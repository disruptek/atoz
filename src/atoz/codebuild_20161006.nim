
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

  OpenApiRestCall_592365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592365): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDeleteBuilds_592704 = ref object of OpenApiRestCall_592365
proc url_BatchDeleteBuilds_592706(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteBuilds_592705(path: JsonNode; query: JsonNode;
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
  var valid_592831 = header.getOrDefault("X-Amz-Target")
  valid_592831 = validateParameter(valid_592831, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_592831 != nil:
    section.add "X-Amz-Target", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_BatchDeleteBuilds_592704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_BatchDeleteBuilds_592704; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_592934 = newJObject()
  if body != nil:
    body_592934 = body
  result = call_592933.call(nil, nil, nil, nil, body_592934)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_592704(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_592705, base: "/",
    url: url_BatchDeleteBuilds_592706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_592973 = ref object of OpenApiRestCall_592365
proc url_BatchGetBuilds_592975(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetBuilds_592974(path: JsonNode; query: JsonNode;
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
  var valid_592976 = header.getOrDefault("X-Amz-Target")
  valid_592976 = validateParameter(valid_592976, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_592976 != nil:
    section.add "X-Amz-Target", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592985: Call_BatchGetBuilds_592973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about builds.
  ## 
  let valid = call_592985.validator(path, query, header, formData, body)
  let scheme = call_592985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592985.url(scheme.get, call_592985.host, call_592985.base,
                         call_592985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592985, url, valid)

proc call*(call_592986: Call_BatchGetBuilds_592973; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about builds.
  ##   body: JObject (required)
  var body_592987 = newJObject()
  if body != nil:
    body_592987 = body
  result = call_592986.call(nil, nil, nil, nil, body_592987)

var batchGetBuilds* = Call_BatchGetBuilds_592973(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_592974, base: "/", url: url_BatchGetBuilds_592975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_592988 = ref object of OpenApiRestCall_592365
proc url_BatchGetProjects_592990(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetProjects_592989(path: JsonNode; query: JsonNode;
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
  var valid_592991 = header.getOrDefault("X-Amz-Target")
  valid_592991 = validateParameter(valid_592991, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_592991 != nil:
    section.add "X-Amz-Target", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Signature")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Signature", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Content-Sha256", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Date")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Date", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Credential")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Credential", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Security-Token")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Security-Token", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Algorithm")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Algorithm", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-SignedHeaders", valid_592998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_BatchGetProjects_592988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about build projects.
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_BatchGetProjects_592988; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about build projects.
  ##   body: JObject (required)
  var body_593002 = newJObject()
  if body != nil:
    body_593002 = body
  result = call_593001.call(nil, nil, nil, nil, body_593002)

var batchGetProjects* = Call_BatchGetProjects_592988(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_592989, base: "/",
    url: url_BatchGetProjects_592990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_593003 = ref object of OpenApiRestCall_592365
proc url_CreateProject_593005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_593004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593006 = header.getOrDefault("X-Amz-Target")
  valid_593006 = validateParameter(valid_593006, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_593006 != nil:
    section.add "X-Amz-Target", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Algorithm")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Algorithm", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-SignedHeaders", valid_593013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_CreateProject_593003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_CreateProject_593003; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_593017 = newJObject()
  if body != nil:
    body_593017 = body
  result = call_593016.call(nil, nil, nil, nil, body_593017)

var createProject* = Call_CreateProject_593003(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_593004, base: "/", url: url_CreateProject_593005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_593018 = ref object of OpenApiRestCall_592365
proc url_CreateWebhook_593020(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWebhook_593019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593021 = header.getOrDefault("X-Amz-Target")
  valid_593021 = validateParameter(valid_593021, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_593021 != nil:
    section.add "X-Amz-Target", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593030: Call_CreateWebhook_593018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_593030.validator(path, query, header, formData, body)
  let scheme = call_593030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593030.url(scheme.get, call_593030.host, call_593030.base,
                         call_593030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593030, url, valid)

proc call*(call_593031: Call_CreateWebhook_593018; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_593032 = newJObject()
  if body != nil:
    body_593032 = body
  result = call_593031.call(nil, nil, nil, nil, body_593032)

var createWebhook* = Call_CreateWebhook_593018(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_593019, base: "/", url: url_CreateWebhook_593020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_593033 = ref object of OpenApiRestCall_592365
proc url_DeleteProject_593035(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProject_593034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593036 = header.getOrDefault("X-Amz-Target")
  valid_593036 = validateParameter(valid_593036, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_593036 != nil:
    section.add "X-Amz-Target", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_DeleteProject_593033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a build project.
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_DeleteProject_593033; body: JsonNode): Recallable =
  ## deleteProject
  ## Deletes a build project.
  ##   body: JObject (required)
  var body_593047 = newJObject()
  if body != nil:
    body_593047 = body
  result = call_593046.call(nil, nil, nil, nil, body_593047)

var deleteProject* = Call_DeleteProject_593033(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_593034, base: "/", url: url_DeleteProject_593035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_593048 = ref object of OpenApiRestCall_592365
proc url_DeleteSourceCredentials_593050(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSourceCredentials_593049(path: JsonNode; query: JsonNode;
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
  var valid_593051 = header.getOrDefault("X-Amz-Target")
  valid_593051 = validateParameter(valid_593051, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_593051 != nil:
    section.add "X-Amz-Target", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_DeleteSourceCredentials_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_DeleteSourceCredentials_593048; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_593062 = newJObject()
  if body != nil:
    body_593062 = body
  result = call_593061.call(nil, nil, nil, nil, body_593062)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_593048(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_593049, base: "/",
    url: url_DeleteSourceCredentials_593050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_593063 = ref object of OpenApiRestCall_592365
proc url_DeleteWebhook_593065(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWebhook_593064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593066 = header.getOrDefault("X-Amz-Target")
  valid_593066 = validateParameter(valid_593066, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_593066 != nil:
    section.add "X-Amz-Target", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Signature")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Signature", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Content-Sha256", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Date")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Date", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Credential")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Credential", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Security-Token")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Security-Token", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Algorithm")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Algorithm", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-SignedHeaders", valid_593073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_DeleteWebhook_593063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_DeleteWebhook_593063; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_593077 = newJObject()
  if body != nil:
    body_593077 = body
  result = call_593076.call(nil, nil, nil, nil, body_593077)

var deleteWebhook* = Call_DeleteWebhook_593063(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_593064, base: "/", url: url_DeleteWebhook_593065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_593078 = ref object of OpenApiRestCall_592365
proc url_ImportSourceCredentials_593080(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportSourceCredentials_593079(path: JsonNode; query: JsonNode;
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
  var valid_593081 = header.getOrDefault("X-Amz-Target")
  valid_593081 = validateParameter(valid_593081, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_593081 != nil:
    section.add "X-Amz-Target", valid_593081
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

proc call*(call_593090: Call_ImportSourceCredentials_593078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_ImportSourceCredentials_593078; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_593092 = newJObject()
  if body != nil:
    body_593092 = body
  result = call_593091.call(nil, nil, nil, nil, body_593092)

var importSourceCredentials* = Call_ImportSourceCredentials_593078(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_593079, base: "/",
    url: url_ImportSourceCredentials_593080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_593093 = ref object of OpenApiRestCall_592365
proc url_InvalidateProjectCache_593095(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InvalidateProjectCache_593094(path: JsonNode; query: JsonNode;
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
  var valid_593096 = header.getOrDefault("X-Amz-Target")
  valid_593096 = validateParameter(valid_593096, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_593096 != nil:
    section.add "X-Amz-Target", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593105: Call_InvalidateProjectCache_593093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_593105.validator(path, query, header, formData, body)
  let scheme = call_593105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593105.url(scheme.get, call_593105.host, call_593105.base,
                         call_593105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593105, url, valid)

proc call*(call_593106: Call_InvalidateProjectCache_593093; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_593107 = newJObject()
  if body != nil:
    body_593107 = body
  result = call_593106.call(nil, nil, nil, nil, body_593107)

var invalidateProjectCache* = Call_InvalidateProjectCache_593093(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_593094, base: "/",
    url: url_InvalidateProjectCache_593095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_593108 = ref object of OpenApiRestCall_592365
proc url_ListBuilds_593110(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuilds_593109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593111 = header.getOrDefault("X-Amz-Target")
  valid_593111 = validateParameter(valid_593111, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_593111 != nil:
    section.add "X-Amz-Target", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Signature")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Signature", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Content-Sha256", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Date")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Date", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Credential")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Credential", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Security-Token")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Security-Token", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Algorithm")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Algorithm", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-SignedHeaders", valid_593118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593120: Call_ListBuilds_593108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_593120.validator(path, query, header, formData, body)
  let scheme = call_593120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593120.url(scheme.get, call_593120.host, call_593120.base,
                         call_593120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593120, url, valid)

proc call*(call_593121: Call_ListBuilds_593108; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_593122 = newJObject()
  if body != nil:
    body_593122 = body
  result = call_593121.call(nil, nil, nil, nil, body_593122)

var listBuilds* = Call_ListBuilds_593108(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                      validator: validate_ListBuilds_593109,
                                      base: "/", url: url_ListBuilds_593110,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_593123 = ref object of OpenApiRestCall_592365
proc url_ListBuildsForProject_593125(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuildsForProject_593124(path: JsonNode; query: JsonNode;
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
  var valid_593126 = header.getOrDefault("X-Amz-Target")
  valid_593126 = validateParameter(valid_593126, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_593126 != nil:
    section.add "X-Amz-Target", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Signature")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Signature", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Content-Sha256", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Date")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Date", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Credential")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Credential", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Security-Token")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Security-Token", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Algorithm")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Algorithm", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-SignedHeaders", valid_593133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593135: Call_ListBuildsForProject_593123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_593135.validator(path, query, header, formData, body)
  let scheme = call_593135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593135.url(scheme.get, call_593135.host, call_593135.base,
                         call_593135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593135, url, valid)

proc call*(call_593136: Call_ListBuildsForProject_593123; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_593137 = newJObject()
  if body != nil:
    body_593137 = body
  result = call_593136.call(nil, nil, nil, nil, body_593137)

var listBuildsForProject* = Call_ListBuildsForProject_593123(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_593124, base: "/",
    url: url_ListBuildsForProject_593125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_593138 = ref object of OpenApiRestCall_592365
proc url_ListCuratedEnvironmentImages_593140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCuratedEnvironmentImages_593139(path: JsonNode; query: JsonNode;
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
  var valid_593141 = header.getOrDefault("X-Amz-Target")
  valid_593141 = validateParameter(valid_593141, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_593141 != nil:
    section.add "X-Amz-Target", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Signature")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Signature", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Content-Sha256", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Date")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Date", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Credential")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Credential", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Security-Token")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Security-Token", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Algorithm")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Algorithm", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-SignedHeaders", valid_593148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593150: Call_ListCuratedEnvironmentImages_593138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_593150.validator(path, query, header, formData, body)
  let scheme = call_593150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593150.url(scheme.get, call_593150.host, call_593150.base,
                         call_593150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593150, url, valid)

proc call*(call_593151: Call_ListCuratedEnvironmentImages_593138; body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_593152 = newJObject()
  if body != nil:
    body_593152 = body
  result = call_593151.call(nil, nil, nil, nil, body_593152)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_593138(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_593139, base: "/",
    url: url_ListCuratedEnvironmentImages_593140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_593153 = ref object of OpenApiRestCall_592365
proc url_ListProjects_593155(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_593154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593156 = header.getOrDefault("X-Amz-Target")
  valid_593156 = validateParameter(valid_593156, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_593156 != nil:
    section.add "X-Amz-Target", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Signature", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Content-Sha256", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Date")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Date", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Credential")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Credential", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Security-Token")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Security-Token", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Algorithm")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Algorithm", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-SignedHeaders", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_ListProjects_593153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_ListProjects_593153; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_593167 = newJObject()
  if body != nil:
    body_593167 = body
  result = call_593166.call(nil, nil, nil, nil, body_593167)

var listProjects* = Call_ListProjects_593153(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_593154, base: "/", url: url_ListProjects_593155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_593168 = ref object of OpenApiRestCall_592365
proc url_ListSourceCredentials_593170(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSourceCredentials_593169(path: JsonNode; query: JsonNode;
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
  var valid_593171 = header.getOrDefault("X-Amz-Target")
  valid_593171 = validateParameter(valid_593171, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_593171 != nil:
    section.add "X-Amz-Target", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593180: Call_ListSourceCredentials_593168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_593180.validator(path, query, header, formData, body)
  let scheme = call_593180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593180.url(scheme.get, call_593180.host, call_593180.base,
                         call_593180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593180, url, valid)

proc call*(call_593181: Call_ListSourceCredentials_593168; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_593182 = newJObject()
  if body != nil:
    body_593182 = body
  result = call_593181.call(nil, nil, nil, nil, body_593182)

var listSourceCredentials* = Call_ListSourceCredentials_593168(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_593169, base: "/",
    url: url_ListSourceCredentials_593170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_593183 = ref object of OpenApiRestCall_592365
proc url_StartBuild_593185(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBuild_593184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593186 = header.getOrDefault("X-Amz-Target")
  valid_593186 = validateParameter(valid_593186, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_593186 != nil:
    section.add "X-Amz-Target", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Security-Token")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Security-Token", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Algorithm")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Algorithm", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-SignedHeaders", valid_593193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593195: Call_StartBuild_593183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_593195.validator(path, query, header, formData, body)
  let scheme = call_593195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593195.url(scheme.get, call_593195.host, call_593195.base,
                         call_593195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593195, url, valid)

proc call*(call_593196: Call_StartBuild_593183; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_593197 = newJObject()
  if body != nil:
    body_593197 = body
  result = call_593196.call(nil, nil, nil, nil, body_593197)

var startBuild* = Call_StartBuild_593183(name: "startBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                      validator: validate_StartBuild_593184,
                                      base: "/", url: url_StartBuild_593185,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_593198 = ref object of OpenApiRestCall_592365
proc url_StopBuild_593200(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopBuild_593199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593201 = header.getOrDefault("X-Amz-Target")
  valid_593201 = validateParameter(valid_593201, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_593201 != nil:
    section.add "X-Amz-Target", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Signature")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Signature", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Content-Sha256", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Date")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Date", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Credential")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Credential", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Security-Token")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Security-Token", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Algorithm")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Algorithm", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-SignedHeaders", valid_593208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593210: Call_StopBuild_593198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_593210.validator(path, query, header, formData, body)
  let scheme = call_593210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593210.url(scheme.get, call_593210.host, call_593210.base,
                         call_593210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593210, url, valid)

proc call*(call_593211: Call_StopBuild_593198; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_593212 = newJObject()
  if body != nil:
    body_593212 = body
  result = call_593211.call(nil, nil, nil, nil, body_593212)

var stopBuild* = Call_StopBuild_593198(name: "stopBuild", meth: HttpMethod.HttpPost,
                                    host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                    validator: validate_StopBuild_593199,
                                    base: "/", url: url_StopBuild_593200,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_593213 = ref object of OpenApiRestCall_592365
proc url_UpdateProject_593215(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_593214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593216 = header.getOrDefault("X-Amz-Target")
  valid_593216 = validateParameter(valid_593216, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_593216 != nil:
    section.add "X-Amz-Target", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Signature")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Signature", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Content-Sha256", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Date")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Date", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Credential")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Credential", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Security-Token")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Security-Token", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Algorithm")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Algorithm", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-SignedHeaders", valid_593223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593225: Call_UpdateProject_593213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_593225.validator(path, query, header, formData, body)
  let scheme = call_593225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593225.url(scheme.get, call_593225.host, call_593225.base,
                         call_593225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593225, url, valid)

proc call*(call_593226: Call_UpdateProject_593213; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_593227 = newJObject()
  if body != nil:
    body_593227 = body
  result = call_593226.call(nil, nil, nil, nil, body_593227)

var updateProject* = Call_UpdateProject_593213(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_593214, base: "/", url: url_UpdateProject_593215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_593228 = ref object of OpenApiRestCall_592365
proc url_UpdateWebhook_593230(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWebhook_593229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593231 = header.getOrDefault("X-Amz-Target")
  valid_593231 = validateParameter(valid_593231, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_593231 != nil:
    section.add "X-Amz-Target", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Signature")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Signature", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Content-Sha256", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Date")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Date", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Credential")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Credential", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Security-Token")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Security-Token", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Algorithm")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Algorithm", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-SignedHeaders", valid_593238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593240: Call_UpdateWebhook_593228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_593240.validator(path, query, header, formData, body)
  let scheme = call_593240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593240.url(scheme.get, call_593240.host, call_593240.base,
                         call_593240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593240, url, valid)

proc call*(call_593241: Call_UpdateWebhook_593228; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_593242 = newJObject()
  if body != nil:
    body_593242 = body
  result = call_593241.call(nil, nil, nil, nil, body_593242)

var updateWebhook* = Call_UpdateWebhook_593228(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_593229, base: "/", url: url_UpdateWebhook_593230,
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
