
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodePipeline
## version: 2015-07-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodePipeline</fullname> <p> <b>Overview</b> </p> <p>This is the AWS CodePipeline API Reference. This guide provides descriptions of the actions and data types for AWS CodePipeline. Some functionality for your pipeline can only be configured through the API. For more information, see the <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html">AWS CodePipeline User Guide</a>.</p> <p>You can use the AWS CodePipeline API to work with pipelines, stages, actions, and transitions.</p> <p> <i>Pipelines</i> are models of automated release processes. Each pipeline is uniquely named, and consists of stages, actions, and transitions. </p> <p>You can work with pipelines by calling:</p> <ul> <li> <p> <a>CreatePipeline</a>, which creates a uniquely named pipeline.</p> </li> <li> <p> <a>DeletePipeline</a>, which deletes the specified pipeline.</p> </li> <li> <p> <a>GetPipeline</a>, which returns information about the pipeline structure and pipeline metadata, including the pipeline Amazon Resource Name (ARN).</p> </li> <li> <p> <a>GetPipelineExecution</a>, which returns information about a specific execution of a pipeline.</p> </li> <li> <p> <a>GetPipelineState</a>, which returns information about the current state of the stages and actions of a pipeline.</p> </li> <li> <p> <a>ListActionExecutions</a>, which returns action-level details for past executions. The details include full stage and action-level details, including individual action duration, status, any errors that occurred during the execution, and input and output artifact location details.</p> </li> <li> <p> <a>ListPipelines</a>, which gets a summary of all of the pipelines associated with your account.</p> </li> <li> <p> <a>ListPipelineExecutions</a>, which gets a summary of the most recent executions for a pipeline.</p> </li> <li> <p> <a>StartPipelineExecution</a>, which runs the most recent revision of an artifact through the pipeline.</p> </li> <li> <p> <a>StopPipelineExecution</a>, which stops the specified pipeline execution from continuing through the pipeline.</p> </li> <li> <p> <a>UpdatePipeline</a>, which updates a pipeline with edits or changes to the structure of the pipeline.</p> </li> </ul> <p>Pipelines include <i>stages</i>. Each stage contains one or more actions that must complete before the next stage begins. A stage results in success or failure. If a stage fails, the pipeline stops at that stage and remains stopped until either a new version of an artifact appears in the source location, or a user takes action to rerun the most recent artifact through the pipeline. You can call <a>GetPipelineState</a>, which displays the status of a pipeline, including the status of stages in the pipeline, or <a>GetPipeline</a>, which returns the entire structure of the pipeline, including the stages of that pipeline. For more information about the structure of stages and actions, see <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-structure.html">AWS CodePipeline Pipeline Structure Reference</a>.</p> <p>Pipeline stages include <i>actions</i> that are categorized into categories such as source or build actions performed in a stage of a pipeline. For example, you can use a source action to import artifacts into a pipeline from a source such as Amazon S3. Like stages, you do not work with actions directly in most cases, but you do define and interact with actions when working with pipeline operations such as <a>CreatePipeline</a> and <a>GetPipelineState</a>. Valid action categories are:</p> <ul> <li> <p>Source</p> </li> <li> <p>Build</p> </li> <li> <p>Test</p> </li> <li> <p>Deploy</p> </li> <li> <p>Approval</p> </li> <li> <p>Invoke</p> </li> </ul> <p>Pipelines also include <i>transitions</i>, which allow the transition of artifacts from one stage to the next in a pipeline after the actions in one stage complete.</p> <p>You can work with transitions by calling:</p> <ul> <li> <p> <a>DisableStageTransition</a>, which prevents artifacts from transitioning to the next stage in a pipeline.</p> </li> <li> <p> <a>EnableStageTransition</a>, which enables transition of artifacts between stages in a pipeline. </p> </li> </ul> <p> <b>Using the API to integrate with AWS CodePipeline</b> </p> <p>For third-party integrators or developers who want to create their own integrations with AWS CodePipeline, the expected sequence varies from the standard API user. To integrate with AWS CodePipeline, developers need to work with the following items:</p> <p> <b>Jobs</b>, which are instances of an action. For example, a job for a source action might import a revision of an artifact from a source. </p> <p>You can work with jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeJob</a>, which confirms whether a job worker has received the specified job.</p> </li> <li> <p> <a>GetJobDetails</a>, which returns the details of a job.</p> </li> <li> <p> <a>PollForJobs</a>, which determines whether there are any jobs to act on.</p> </li> <li> <p> <a>PutJobFailureResult</a>, which provides details of a job failure. </p> </li> <li> <p> <a>PutJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul> <p> <b>Third party jobs</b>, which are instances of an action created by a partner action and integrated into AWS CodePipeline. Partner actions are created by members of the AWS Partner Network.</p> <p>You can work with third party jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeThirdPartyJob</a>, which confirms whether a job worker has received the specified job.</p> </li> <li> <p> <a>GetThirdPartyJobDetails</a>, which requests the details of a job for a partner action.</p> </li> <li> <p> <a>PollForThirdPartyJobs</a>, which determines whether there are any jobs to act on. </p> </li> <li> <p> <a>PutThirdPartyJobFailureResult</a>, which provides details of a job failure.</p> </li> <li> <p> <a>PutThirdPartyJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codepipeline/
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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codepipeline.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codepipeline.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codepipeline.us-west-2.amazonaws.com",
                           "eu-west-2": "codepipeline.eu-west-2.amazonaws.com", "ap-northeast-3": "codepipeline.ap-northeast-3.amazonaws.com", "eu-central-1": "codepipeline.eu-central-1.amazonaws.com",
                           "us-east-2": "codepipeline.us-east-2.amazonaws.com",
                           "us-east-1": "codepipeline.us-east-1.amazonaws.com", "cn-northwest-1": "codepipeline.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codepipeline.ap-south-1.amazonaws.com", "eu-north-1": "codepipeline.eu-north-1.amazonaws.com", "ap-northeast-2": "codepipeline.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codepipeline.us-west-1.amazonaws.com", "us-gov-east-1": "codepipeline.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codepipeline.eu-west-3.amazonaws.com", "cn-north-1": "codepipeline.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codepipeline.sa-east-1.amazonaws.com",
                           "eu-west-1": "codepipeline.eu-west-1.amazonaws.com", "us-gov-west-1": "codepipeline.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codepipeline.ap-southeast-2.amazonaws.com", "ca-central-1": "codepipeline.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codepipeline.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codepipeline.ap-southeast-1.amazonaws.com",
      "us-west-2": "codepipeline.us-west-2.amazonaws.com",
      "eu-west-2": "codepipeline.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codepipeline.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codepipeline.eu-central-1.amazonaws.com",
      "us-east-2": "codepipeline.us-east-2.amazonaws.com",
      "us-east-1": "codepipeline.us-east-1.amazonaws.com",
      "cn-northwest-1": "codepipeline.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codepipeline.ap-south-1.amazonaws.com",
      "eu-north-1": "codepipeline.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codepipeline.ap-northeast-2.amazonaws.com",
      "us-west-1": "codepipeline.us-west-1.amazonaws.com",
      "us-gov-east-1": "codepipeline.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codepipeline.eu-west-3.amazonaws.com",
      "cn-north-1": "codepipeline.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codepipeline.sa-east-1.amazonaws.com",
      "eu-west-1": "codepipeline.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codepipeline.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codepipeline.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codepipeline.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codepipeline"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AcknowledgeJob_21625779 = ref object of OpenApiRestCall_21625435
proc url_AcknowledgeJob_21625781(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcknowledgeJob_21625780(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AcknowledgeJob_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AcknowledgeJob_21625779; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var acknowledgeJob* = Call_AcknowledgeJob_21625779(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_21625780, base: "/",
    makeUrl: url_AcknowledgeJob_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_21626029 = ref object of OpenApiRestCall_21625435
proc url_AcknowledgeThirdPartyJob_21626031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcknowledgeThirdPartyJob_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_AcknowledgeThirdPartyJob_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AcknowledgeThirdPartyJob_21626029; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_21626029(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_21626030, base: "/",
    makeUrl: url_AcknowledgeThirdPartyJob_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_21626044 = ref object of OpenApiRestCall_21625435
proc url_CreateCustomActionType_21626046(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCustomActionType_21626045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_CreateCustomActionType_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_CreateCustomActionType_21626044; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var createCustomActionType* = Call_CreateCustomActionType_21626044(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_21626045, base: "/",
    makeUrl: url_CreateCustomActionType_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_21626059 = ref object of OpenApiRestCall_21625435
proc url_CreatePipeline_21626061(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_21626060(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_CreatePipeline_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CreatePipeline_21626059; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var createPipeline* = Call_CreatePipeline_21626059(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_21626060, base: "/",
    makeUrl: url_CreatePipeline_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_21626074 = ref object of OpenApiRestCall_21625435
proc url_DeleteCustomActionType_21626076(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCustomActionType_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
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
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_DeleteCustomActionType_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_DeleteCustomActionType_21626074; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var deleteCustomActionType* = Call_DeleteCustomActionType_21626074(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_21626075, base: "/",
    makeUrl: url_DeleteCustomActionType_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_21626089 = ref object of OpenApiRestCall_21625435
proc url_DeletePipeline_21626091(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePipeline_21626090(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified pipeline.
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_DeletePipeline_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_DeletePipeline_21626089; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var deletePipeline* = Call_DeletePipeline_21626089(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_21626090, base: "/",
    makeUrl: url_DeletePipeline_21626091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_21626104 = ref object of OpenApiRestCall_21625435
proc url_DeleteWebhook_21626106(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWebhook_21626105(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_DeleteWebhook_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_DeleteWebhook_21626104; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var deleteWebhook* = Call_DeleteWebhook_21626104(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_21626105, base: "/",
    makeUrl: url_DeleteWebhook_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_21626119 = ref object of OpenApiRestCall_21625435
proc url_DeregisterWebhookWithThirdParty_21626121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterWebhookWithThirdParty_21626120(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_DeregisterWebhookWithThirdParty_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_DeregisterWebhookWithThirdParty_21626119;
          body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_21626119(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_21626120, base: "/",
    makeUrl: url_DeregisterWebhookWithThirdParty_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_21626134 = ref object of OpenApiRestCall_21625435
proc url_DisableStageTransition_21626136(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableStageTransition_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
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

proc call*(call_21626146: Call_DisableStageTransition_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_DisableStageTransition_21626134; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var disableStageTransition* = Call_DisableStageTransition_21626134(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_21626135, base: "/",
    makeUrl: url_DisableStageTransition_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_21626149 = ref object of OpenApiRestCall_21625435
proc url_EnableStageTransition_21626151(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableStageTransition_21626150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_EnableStageTransition_21626149;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_EnableStageTransition_21626149; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var enableStageTransition* = Call_EnableStageTransition_21626149(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_21626150, base: "/",
    makeUrl: url_EnableStageTransition_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_21626164 = ref object of OpenApiRestCall_21625435
proc url_GetJobDetails_21626166(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobDetails_21626165(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
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

proc call*(call_21626176: Call_GetJobDetails_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_GetJobDetails_21626164; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var getJobDetails* = Call_GetJobDetails_21626164(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_21626165, base: "/",
    makeUrl: url_GetJobDetails_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_21626179 = ref object of OpenApiRestCall_21625435
proc url_GetPipeline_21626181(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipeline_21626180(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
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

proc call*(call_21626191: Call_GetPipeline_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_GetPipeline_21626179; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var getPipeline* = Call_GetPipeline_21626179(name: "getPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
    validator: validate_GetPipeline_21626180, base: "/", makeUrl: url_GetPipeline_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_21626194 = ref object of OpenApiRestCall_21625435
proc url_GetPipelineExecution_21626196(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipelineExecution_21626195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_GetPipelineExecution_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_GetPipelineExecution_21626194; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var getPipelineExecution* = Call_GetPipelineExecution_21626194(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_21626195, base: "/",
    makeUrl: url_GetPipelineExecution_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_21626209 = ref object of OpenApiRestCall_21625435
proc url_GetPipelineState_21626211(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipelineState_21626210(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_GetPipelineState_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_GetPipelineState_21626209; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var getPipelineState* = Call_GetPipelineState_21626209(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_21626210, base: "/",
    makeUrl: url_GetPipelineState_21626211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_21626224 = ref object of OpenApiRestCall_21625435
proc url_GetThirdPartyJobDetails_21626226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetThirdPartyJobDetails_21626225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_GetThirdPartyJobDetails_21626224;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_GetThirdPartyJobDetails_21626224; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_21626224(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_21626225, base: "/",
    makeUrl: url_GetThirdPartyJobDetails_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_21626239 = ref object of OpenApiRestCall_21625435
proc url_ListActionExecutions_21626241(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActionExecutions_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626242 = query.getOrDefault("maxResults")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "maxResults", valid_21626242
  var valid_21626243 = query.getOrDefault("nextToken")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "nextToken", valid_21626243
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
      "CodePipeline_20150709.ListActionExecutions"))
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

proc call*(call_21626253: Call_ListActionExecutions_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_ListActionExecutions_21626239; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626256 = newJObject()
  var body_21626257 = newJObject()
  add(query_21626256, "maxResults", newJString(maxResults))
  add(query_21626256, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626257 = body
  result = call_21626254.call(nil, query_21626256, nil, nil, body_21626257)

var listActionExecutions* = Call_ListActionExecutions_21626239(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_21626240, base: "/",
    makeUrl: url_ListActionExecutions_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_21626261 = ref object of OpenApiRestCall_21625435
proc url_ListActionTypes_21626263(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActionTypes_21626262(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626264 = query.getOrDefault("nextToken")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "nextToken", valid_21626264
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
  var valid_21626265 = header.getOrDefault("X-Amz-Date")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Date", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Security-Token", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Target")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_21626267 != nil:
    section.add "X-Amz-Target", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Algorithm", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Signature")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Signature", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Credential")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Credential", valid_21626272
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

proc call*(call_21626274: Call_ListActionTypes_21626261; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_21626274.validator(path, query, header, formData, body, _)
  let scheme = call_21626274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626274.makeUrl(scheme.get, call_21626274.host, call_21626274.base,
                               call_21626274.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626274, uri, valid, _)

proc call*(call_21626275: Call_ListActionTypes_21626261; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626276 = newJObject()
  var body_21626277 = newJObject()
  add(query_21626276, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626277 = body
  result = call_21626275.call(nil, query_21626276, nil, nil, body_21626277)

var listActionTypes* = Call_ListActionTypes_21626261(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_21626262, base: "/",
    makeUrl: url_ListActionTypes_21626263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_21626278 = ref object of OpenApiRestCall_21625435
proc url_ListPipelineExecutions_21626280(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelineExecutions_21626279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626281 = query.getOrDefault("maxResults")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "maxResults", valid_21626281
  var valid_21626282 = query.getOrDefault("nextToken")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "nextToken", valid_21626282
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
  var valid_21626283 = header.getOrDefault("X-Amz-Date")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Date", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Security-Token", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Target")
  valid_21626285 = validateParameter(valid_21626285, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_21626285 != nil:
    section.add "X-Amz-Target", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
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

proc call*(call_21626292: Call_ListPipelineExecutions_21626278;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_21626292.validator(path, query, header, formData, body, _)
  let scheme = call_21626292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626292.makeUrl(scheme.get, call_21626292.host, call_21626292.base,
                               call_21626292.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626292, uri, valid, _)

proc call*(call_21626293: Call_ListPipelineExecutions_21626278; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626294 = newJObject()
  var body_21626295 = newJObject()
  add(query_21626294, "maxResults", newJString(maxResults))
  add(query_21626294, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626295 = body
  result = call_21626293.call(nil, query_21626294, nil, nil, body_21626295)

var listPipelineExecutions* = Call_ListPipelineExecutions_21626278(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_21626279, base: "/",
    makeUrl: url_ListPipelineExecutions_21626280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_21626296 = ref object of OpenApiRestCall_21625435
proc url_ListPipelines_21626298(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_21626297(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626299 = query.getOrDefault("nextToken")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "nextToken", valid_21626299
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
  var valid_21626300 = header.getOrDefault("X-Amz-Date")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Date", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Security-Token", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Target")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_21626302 != nil:
    section.add "X-Amz-Target", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Algorithm", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Signature")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Signature", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Credential")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Credential", valid_21626307
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

proc call*(call_21626309: Call_ListPipelines_21626296; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_21626309.validator(path, query, header, formData, body, _)
  let scheme = call_21626309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626309.makeUrl(scheme.get, call_21626309.host, call_21626309.base,
                               call_21626309.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626309, uri, valid, _)

proc call*(call_21626310: Call_ListPipelines_21626296; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626311 = newJObject()
  var body_21626312 = newJObject()
  add(query_21626311, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626312 = body
  result = call_21626310.call(nil, query_21626311, nil, nil, body_21626312)

var listPipelines* = Call_ListPipelines_21626296(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_21626297, base: "/",
    makeUrl: url_ListPipelines_21626298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626313 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626315(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626316 = query.getOrDefault("maxResults")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "maxResults", valid_21626316
  var valid_21626317 = query.getOrDefault("nextToken")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "nextToken", valid_21626317
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
  var valid_21626318 = header.getOrDefault("X-Amz-Date")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Date", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Security-Token", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Target")
  valid_21626320 = validateParameter(valid_21626320, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_21626320 != nil:
    section.add "X-Amz-Target", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Algorithm", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Signature")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Signature", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Credential")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Credential", valid_21626325
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

proc call*(call_21626327: Call_ListTagsForResource_21626313; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_21626327.validator(path, query, header, formData, body, _)
  let scheme = call_21626327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626327.makeUrl(scheme.get, call_21626327.host, call_21626327.base,
                               call_21626327.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626327, uri, valid, _)

proc call*(call_21626328: Call_ListTagsForResource_21626313; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626329 = newJObject()
  var body_21626330 = newJObject()
  add(query_21626329, "maxResults", newJString(maxResults))
  add(query_21626329, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626330 = body
  result = call_21626328.call(nil, query_21626329, nil, nil, body_21626330)

var listTagsForResource* = Call_ListTagsForResource_21626313(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_21626314, base: "/",
    makeUrl: url_ListTagsForResource_21626315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_21626331 = ref object of OpenApiRestCall_21625435
proc url_ListWebhooks_21626333(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebhooks_21626332(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626334 = query.getOrDefault("NextToken")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "NextToken", valid_21626334
  var valid_21626335 = query.getOrDefault("MaxResults")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "MaxResults", valid_21626335
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
  var valid_21626336 = header.getOrDefault("X-Amz-Date")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Date", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Security-Token", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Target")
  valid_21626338 = validateParameter(valid_21626338, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_21626338 != nil:
    section.add "X-Amz-Target", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Algorithm", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Signature")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Signature", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Credential")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Credential", valid_21626343
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

proc call*(call_21626345: Call_ListWebhooks_21626331; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_ListWebhooks_21626331; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626347 = newJObject()
  var body_21626348 = newJObject()
  add(query_21626347, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626348 = body
  add(query_21626347, "MaxResults", newJString(MaxResults))
  result = call_21626346.call(nil, query_21626347, nil, nil, body_21626348)

var listWebhooks* = Call_ListWebhooks_21626331(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_21626332, base: "/", makeUrl: url_ListWebhooks_21626333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_21626349 = ref object of OpenApiRestCall_21625435
proc url_PollForJobs_21626351(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PollForJobs_21626350(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_21626352 = header.getOrDefault("X-Amz-Date")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Date", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Security-Token", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Target")
  valid_21626354 = validateParameter(valid_21626354, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_21626354 != nil:
    section.add "X-Amz-Target", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Algorithm", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Signature")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Signature", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Credential")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Credential", valid_21626359
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

proc call*(call_21626361: Call_PollForJobs_21626349; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_21626361.validator(path, query, header, formData, body, _)
  let scheme = call_21626361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626361.makeUrl(scheme.get, call_21626361.host, call_21626361.base,
                               call_21626361.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626361, uri, valid, _)

proc call*(call_21626362: Call_PollForJobs_21626349; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_21626363 = newJObject()
  if body != nil:
    body_21626363 = body
  result = call_21626362.call(nil, nil, nil, nil, body_21626363)

var pollForJobs* = Call_PollForJobs_21626349(name: "pollForJobs",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
    validator: validate_PollForJobs_21626350, base: "/", makeUrl: url_PollForJobs_21626351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_21626364 = ref object of OpenApiRestCall_21625435
proc url_PollForThirdPartyJobs_21626366(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PollForThirdPartyJobs_21626365(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
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
  var valid_21626367 = header.getOrDefault("X-Amz-Date")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Date", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Security-Token", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Target")
  valid_21626369 = validateParameter(valid_21626369, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_21626369 != nil:
    section.add "X-Amz-Target", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Algorithm", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Signature")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Signature", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Credential")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Credential", valid_21626374
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

proc call*(call_21626376: Call_PollForThirdPartyJobs_21626364;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_21626376.validator(path, query, header, formData, body, _)
  let scheme = call_21626376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626376.makeUrl(scheme.get, call_21626376.host, call_21626376.base,
                               call_21626376.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626376, uri, valid, _)

proc call*(call_21626377: Call_PollForThirdPartyJobs_21626364; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_21626378 = newJObject()
  if body != nil:
    body_21626378 = body
  result = call_21626377.call(nil, nil, nil, nil, body_21626378)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_21626364(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_21626365, base: "/",
    makeUrl: url_PollForThirdPartyJobs_21626366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_21626379 = ref object of OpenApiRestCall_21625435
proc url_PutActionRevision_21626381(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutActionRevision_21626380(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information to AWS CodePipeline about new revisions to a source.
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
  var valid_21626382 = header.getOrDefault("X-Amz-Date")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Date", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Security-Token", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Target")
  valid_21626384 = validateParameter(valid_21626384, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_21626384 != nil:
    section.add "X-Amz-Target", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Algorithm", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Signature")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Signature", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Credential")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Credential", valid_21626389
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

proc call*(call_21626391: Call_PutActionRevision_21626379; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_21626391.validator(path, query, header, formData, body, _)
  let scheme = call_21626391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626391.makeUrl(scheme.get, call_21626391.host, call_21626391.base,
                               call_21626391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626391, uri, valid, _)

proc call*(call_21626392: Call_PutActionRevision_21626379; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_21626393 = newJObject()
  if body != nil:
    body_21626393 = body
  result = call_21626392.call(nil, nil, nil, nil, body_21626393)

var putActionRevision* = Call_PutActionRevision_21626379(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_21626380, base: "/",
    makeUrl: url_PutActionRevision_21626381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_21626394 = ref object of OpenApiRestCall_21625435
proc url_PutApprovalResult_21626396(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutApprovalResult_21626395(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
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
  var valid_21626397 = header.getOrDefault("X-Amz-Date")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Date", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Security-Token", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Target")
  valid_21626399 = validateParameter(valid_21626399, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_21626399 != nil:
    section.add "X-Amz-Target", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Algorithm", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Signature")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Signature", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Credential")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Credential", valid_21626404
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

proc call*(call_21626406: Call_PutApprovalResult_21626394; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_21626406.validator(path, query, header, formData, body, _)
  let scheme = call_21626406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626406.makeUrl(scheme.get, call_21626406.host, call_21626406.base,
                               call_21626406.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626406, uri, valid, _)

proc call*(call_21626407: Call_PutApprovalResult_21626394; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_21626408 = newJObject()
  if body != nil:
    body_21626408 = body
  result = call_21626407.call(nil, nil, nil, nil, body_21626408)

var putApprovalResult* = Call_PutApprovalResult_21626394(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_21626395, base: "/",
    makeUrl: url_PutApprovalResult_21626396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_21626409 = ref object of OpenApiRestCall_21625435
proc url_PutJobFailureResult_21626411(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutJobFailureResult_21626410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
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
  var valid_21626412 = header.getOrDefault("X-Amz-Date")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Date", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Security-Token", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Target")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_21626414 != nil:
    section.add "X-Amz-Target", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Algorithm", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Signature")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Signature", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Credential")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Credential", valid_21626419
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

proc call*(call_21626421: Call_PutJobFailureResult_21626409; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_21626421.validator(path, query, header, formData, body, _)
  let scheme = call_21626421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626421.makeUrl(scheme.get, call_21626421.host, call_21626421.base,
                               call_21626421.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626421, uri, valid, _)

proc call*(call_21626422: Call_PutJobFailureResult_21626409; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_21626423 = newJObject()
  if body != nil:
    body_21626423 = body
  result = call_21626422.call(nil, nil, nil, nil, body_21626423)

var putJobFailureResult* = Call_PutJobFailureResult_21626409(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_21626410, base: "/",
    makeUrl: url_PutJobFailureResult_21626411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_21626424 = ref object of OpenApiRestCall_21625435
proc url_PutJobSuccessResult_21626426(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutJobSuccessResult_21626425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
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
  var valid_21626427 = header.getOrDefault("X-Amz-Date")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Date", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Security-Token", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Target")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_21626429 != nil:
    section.add "X-Amz-Target", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Algorithm", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Signature")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Signature", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Credential")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Credential", valid_21626434
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

proc call*(call_21626436: Call_PutJobSuccessResult_21626424; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_21626436.validator(path, query, header, formData, body, _)
  let scheme = call_21626436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626436.makeUrl(scheme.get, call_21626436.host, call_21626436.base,
                               call_21626436.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626436, uri, valid, _)

proc call*(call_21626437: Call_PutJobSuccessResult_21626424; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_21626438 = newJObject()
  if body != nil:
    body_21626438 = body
  result = call_21626437.call(nil, nil, nil, nil, body_21626438)

var putJobSuccessResult* = Call_PutJobSuccessResult_21626424(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_21626425, base: "/",
    makeUrl: url_PutJobSuccessResult_21626426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_21626439 = ref object of OpenApiRestCall_21625435
proc url_PutThirdPartyJobFailureResult_21626441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutThirdPartyJobFailureResult_21626440(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
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
  var valid_21626442 = header.getOrDefault("X-Amz-Date")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Date", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Security-Token", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Target")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_21626444 != nil:
    section.add "X-Amz-Target", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Algorithm", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Signature")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Signature", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Credential")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Credential", valid_21626449
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

proc call*(call_21626451: Call_PutThirdPartyJobFailureResult_21626439;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_21626451.validator(path, query, header, formData, body, _)
  let scheme = call_21626451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626451.makeUrl(scheme.get, call_21626451.host, call_21626451.base,
                               call_21626451.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626451, uri, valid, _)

proc call*(call_21626452: Call_PutThirdPartyJobFailureResult_21626439;
          body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_21626453 = newJObject()
  if body != nil:
    body_21626453 = body
  result = call_21626452.call(nil, nil, nil, nil, body_21626453)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_21626439(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_21626440, base: "/",
    makeUrl: url_PutThirdPartyJobFailureResult_21626441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_21626454 = ref object of OpenApiRestCall_21625435
proc url_PutThirdPartyJobSuccessResult_21626456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutThirdPartyJobSuccessResult_21626455(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
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
  var valid_21626457 = header.getOrDefault("X-Amz-Date")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Date", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Security-Token", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Target")
  valid_21626459 = validateParameter(valid_21626459, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_21626459 != nil:
    section.add "X-Amz-Target", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Algorithm", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Signature")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Signature", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Credential")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Credential", valid_21626464
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

proc call*(call_21626466: Call_PutThirdPartyJobSuccessResult_21626454;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_21626466.validator(path, query, header, formData, body, _)
  let scheme = call_21626466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626466.makeUrl(scheme.get, call_21626466.host, call_21626466.base,
                               call_21626466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626466, uri, valid, _)

proc call*(call_21626467: Call_PutThirdPartyJobSuccessResult_21626454;
          body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_21626468 = newJObject()
  if body != nil:
    body_21626468 = body
  result = call_21626467.call(nil, nil, nil, nil, body_21626468)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_21626454(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_21626455, base: "/",
    makeUrl: url_PutThirdPartyJobSuccessResult_21626456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_21626469 = ref object of OpenApiRestCall_21625435
proc url_PutWebhook_21626471(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWebhook_21626470(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
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
  var valid_21626472 = header.getOrDefault("X-Amz-Date")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Date", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Security-Token", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Target")
  valid_21626474 = validateParameter(valid_21626474, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_21626474 != nil:
    section.add "X-Amz-Target", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Algorithm", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Signature")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Signature", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Credential")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Credential", valid_21626479
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

proc call*(call_21626481: Call_PutWebhook_21626469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_21626481.validator(path, query, header, formData, body, _)
  let scheme = call_21626481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626481.makeUrl(scheme.get, call_21626481.host, call_21626481.base,
                               call_21626481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626481, uri, valid, _)

proc call*(call_21626482: Call_PutWebhook_21626469; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_21626483 = newJObject()
  if body != nil:
    body_21626483 = body
  result = call_21626482.call(nil, nil, nil, nil, body_21626483)

var putWebhook* = Call_PutWebhook_21626469(name: "putWebhook",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                        validator: validate_PutWebhook_21626470,
                                        base: "/", makeUrl: url_PutWebhook_21626471,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_21626484 = ref object of OpenApiRestCall_21625435
proc url_RegisterWebhookWithThirdParty_21626486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterWebhookWithThirdParty_21626485(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
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
  var valid_21626487 = header.getOrDefault("X-Amz-Date")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Date", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Security-Token", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Target")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_21626489 != nil:
    section.add "X-Amz-Target", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Algorithm", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Signature")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Signature", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Credential")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Credential", valid_21626494
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

proc call*(call_21626496: Call_RegisterWebhookWithThirdParty_21626484;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_21626496.validator(path, query, header, formData, body, _)
  let scheme = call_21626496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626496.makeUrl(scheme.get, call_21626496.host, call_21626496.base,
                               call_21626496.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626496, uri, valid, _)

proc call*(call_21626497: Call_RegisterWebhookWithThirdParty_21626484;
          body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_21626498 = newJObject()
  if body != nil:
    body_21626498 = body
  result = call_21626497.call(nil, nil, nil, nil, body_21626498)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_21626484(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_21626485, base: "/",
    makeUrl: url_RegisterWebhookWithThirdParty_21626486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_21626499 = ref object of OpenApiRestCall_21625435
proc url_RetryStageExecution_21626501(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetryStageExecution_21626500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
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
  var valid_21626502 = header.getOrDefault("X-Amz-Date")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Date", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Security-Token", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Target")
  valid_21626504 = validateParameter(valid_21626504, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_21626504 != nil:
    section.add "X-Amz-Target", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Algorithm", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Signature")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Signature", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Credential")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Credential", valid_21626509
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

proc call*(call_21626511: Call_RetryStageExecution_21626499; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ## 
  let valid = call_21626511.validator(path, query, header, formData, body, _)
  let scheme = call_21626511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626511.makeUrl(scheme.get, call_21626511.host, call_21626511.base,
                               call_21626511.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626511, uri, valid, _)

proc call*(call_21626512: Call_RetryStageExecution_21626499; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ##   body: JObject (required)
  var body_21626513 = newJObject()
  if body != nil:
    body_21626513 = body
  result = call_21626512.call(nil, nil, nil, nil, body_21626513)

var retryStageExecution* = Call_RetryStageExecution_21626499(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_21626500, base: "/",
    makeUrl: url_RetryStageExecution_21626501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_21626514 = ref object of OpenApiRestCall_21625435
proc url_StartPipelineExecution_21626516(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartPipelineExecution_21626515(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
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
  var valid_21626517 = header.getOrDefault("X-Amz-Date")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Date", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Security-Token", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Target")
  valid_21626519 = validateParameter(valid_21626519, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_21626519 != nil:
    section.add "X-Amz-Target", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Algorithm", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Signature")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Signature", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Credential")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Credential", valid_21626524
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

proc call*(call_21626526: Call_StartPipelineExecution_21626514;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_21626526.validator(path, query, header, formData, body, _)
  let scheme = call_21626526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626526.makeUrl(scheme.get, call_21626526.host, call_21626526.base,
                               call_21626526.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626526, uri, valid, _)

proc call*(call_21626527: Call_StartPipelineExecution_21626514; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_21626528 = newJObject()
  if body != nil:
    body_21626528 = body
  result = call_21626527.call(nil, nil, nil, nil, body_21626528)

var startPipelineExecution* = Call_StartPipelineExecution_21626514(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_21626515, base: "/",
    makeUrl: url_StartPipelineExecution_21626516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopPipelineExecution_21626529 = ref object of OpenApiRestCall_21625435
proc url_StopPipelineExecution_21626531(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopPipelineExecution_21626530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
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
  var valid_21626532 = header.getOrDefault("X-Amz-Date")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Date", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Security-Token", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Target")
  valid_21626534 = validateParameter(valid_21626534, JString, required = true, default = newJString(
      "CodePipeline_20150709.StopPipelineExecution"))
  if valid_21626534 != nil:
    section.add "X-Amz-Target", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Algorithm", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Signature")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Signature", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Credential")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Credential", valid_21626539
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

proc call*(call_21626541: Call_StopPipelineExecution_21626529;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ## 
  let valid = call_21626541.validator(path, query, header, formData, body, _)
  let scheme = call_21626541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626541.makeUrl(scheme.get, call_21626541.host, call_21626541.base,
                               call_21626541.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626541, uri, valid, _)

proc call*(call_21626542: Call_StopPipelineExecution_21626529; body: JsonNode): Recallable =
  ## stopPipelineExecution
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ##   body: JObject (required)
  var body_21626543 = newJObject()
  if body != nil:
    body_21626543 = body
  result = call_21626542.call(nil, nil, nil, nil, body_21626543)

var stopPipelineExecution* = Call_StopPipelineExecution_21626529(
    name: "stopPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StopPipelineExecution",
    validator: validate_StopPipelineExecution_21626530, base: "/",
    makeUrl: url_StopPipelineExecution_21626531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626544 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626546(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626545(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
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
  var valid_21626547 = header.getOrDefault("X-Amz-Date")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Date", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Security-Token", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Target")
  valid_21626549 = validateParameter(valid_21626549, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_21626549 != nil:
    section.add "X-Amz-Target", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Algorithm", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Signature")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Signature", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Credential")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Credential", valid_21626554
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

proc call*(call_21626556: Call_TagResource_21626544; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_21626556.validator(path, query, header, formData, body, _)
  let scheme = call_21626556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626556.makeUrl(scheme.get, call_21626556.host, call_21626556.base,
                               call_21626556.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626556, uri, valid, _)

proc call*(call_21626557: Call_TagResource_21626544; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_21626558 = newJObject()
  if body != nil:
    body_21626558 = body
  result = call_21626557.call(nil, nil, nil, nil, body_21626558)

var tagResource* = Call_TagResource_21626544(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
    validator: validate_TagResource_21626545, base: "/", makeUrl: url_TagResource_21626546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626559 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626561(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626560(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes tags from an AWS resource.
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
  var valid_21626562 = header.getOrDefault("X-Amz-Date")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Date", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Security-Token", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Target")
  valid_21626564 = validateParameter(valid_21626564, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_21626564 != nil:
    section.add "X-Amz-Target", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Algorithm", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Signature")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Signature", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Credential")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Credential", valid_21626569
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

proc call*(call_21626571: Call_UntagResource_21626559; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_21626571.validator(path, query, header, formData, body, _)
  let scheme = call_21626571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626571.makeUrl(scheme.get, call_21626571.host, call_21626571.base,
                               call_21626571.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626571, uri, valid, _)

proc call*(call_21626572: Call_UntagResource_21626559; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_21626573 = newJObject()
  if body != nil:
    body_21626573 = body
  result = call_21626572.call(nil, nil, nil, nil, body_21626573)

var untagResource* = Call_UntagResource_21626559(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_21626560, base: "/",
    makeUrl: url_UntagResource_21626561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_21626574 = ref object of OpenApiRestCall_21625435
proc url_UpdatePipeline_21626576(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePipeline_21626575(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
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
  var valid_21626577 = header.getOrDefault("X-Amz-Date")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Date", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Security-Token", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Target")
  valid_21626579 = validateParameter(valid_21626579, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_21626579 != nil:
    section.add "X-Amz-Target", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Algorithm", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Signature")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Signature", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Credential")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Credential", valid_21626584
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

proc call*(call_21626586: Call_UpdatePipeline_21626574; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_21626586.validator(path, query, header, formData, body, _)
  let scheme = call_21626586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626586.makeUrl(scheme.get, call_21626586.host, call_21626586.base,
                               call_21626586.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626586, uri, valid, _)

proc call*(call_21626587: Call_UpdatePipeline_21626574; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_21626588 = newJObject()
  if body != nil:
    body_21626588 = body
  result = call_21626587.call(nil, nil, nil, nil, body_21626588)

var updatePipeline* = Call_UpdatePipeline_21626574(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_21626575, base: "/",
    makeUrl: url_UpdatePipeline_21626576, schemes: {Scheme.Https, Scheme.Http})
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