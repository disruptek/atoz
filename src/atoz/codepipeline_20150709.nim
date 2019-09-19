
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodePipeline
## version: 2015-07-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodePipeline</fullname> <p> <b>Overview</b> </p> <p>This is the AWS CodePipeline API Reference. This guide provides descriptions of the actions and data types for AWS CodePipeline. Some functionality for your pipeline is only configurable through the API. For additional information, see the <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html">AWS CodePipeline User Guide</a>.</p> <p>You can use the AWS CodePipeline API to work with pipelines, stages, actions, and transitions, as described below.</p> <p> <i>Pipelines</i> are models of automated release processes. Each pipeline is uniquely named, and consists of stages, actions, and transitions. </p> <p>You can work with pipelines by calling:</p> <ul> <li> <p> <a>CreatePipeline</a>, which creates a uniquely-named pipeline.</p> </li> <li> <p> <a>DeletePipeline</a>, which deletes the specified pipeline.</p> </li> <li> <p> <a>GetPipeline</a>, which returns information about the pipeline structure and pipeline metadata, including the pipeline Amazon Resource Name (ARN).</p> </li> <li> <p> <a>GetPipelineExecution</a>, which returns information about a specific execution of a pipeline.</p> </li> <li> <p> <a>GetPipelineState</a>, which returns information about the current state of the stages and actions of a pipeline.</p> </li> <li> <p> <a>ListActionExecutions</a>, which returns action-level details for past executions. The details include full stage and action-level details, including individual action duration, status, any errors which occurred during the execution, and input and output artifact location details.</p> </li> <li> <p> <a>ListPipelines</a>, which gets a summary of all of the pipelines associated with your account.</p> </li> <li> <p> <a>ListPipelineExecutions</a>, which gets a summary of the most recent executions for a pipeline.</p> </li> <li> <p> <a>StartPipelineExecution</a>, which runs the the most recent revision of an artifact through the pipeline.</p> </li> <li> <p> <a>UpdatePipeline</a>, which updates a pipeline with edits or changes to the structure of the pipeline.</p> </li> </ul> <p>Pipelines include <i>stages</i>. Each stage contains one or more actions that must complete before the next stage begins. A stage will result in success or failure. If a stage fails, then the pipeline stops at that stage and will remain stopped until either a new version of an artifact appears in the source location, or a user takes action to re-run the most recent artifact through the pipeline. You can call <a>GetPipelineState</a>, which displays the status of a pipeline, including the status of stages in the pipeline, or <a>GetPipeline</a>, which returns the entire structure of the pipeline, including the stages of that pipeline. For more information about the structure of stages and actions, also refer to the <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-structure.html">AWS CodePipeline Pipeline Structure Reference</a>.</p> <p>Pipeline stages include <i>actions</i>, which are categorized into categories such as source or build actions performed within a stage of a pipeline. For example, you can use a source action to import artifacts into a pipeline from a source such as Amazon S3. Like stages, you do not work with actions directly in most cases, but you do define and interact with actions when working with pipeline operations such as <a>CreatePipeline</a> and <a>GetPipelineState</a>. Valid action categories are:</p> <ul> <li> <p>Source</p> </li> <li> <p>Build</p> </li> <li> <p>Test</p> </li> <li> <p>Deploy</p> </li> <li> <p>Approval</p> </li> <li> <p>Invoke</p> </li> </ul> <p>Pipelines also include <i>transitions</i>, which allow the transition of artifacts from one stage to the next in a pipeline after the actions in one stage complete.</p> <p>You can work with transitions by calling:</p> <ul> <li> <p> <a>DisableStageTransition</a>, which prevents artifacts from transitioning to the next stage in a pipeline.</p> </li> <li> <p> <a>EnableStageTransition</a>, which enables transition of artifacts between stages in a pipeline. </p> </li> </ul> <p> <b>Using the API to integrate with AWS CodePipeline</b> </p> <p>For third-party integrators or developers who want to create their own integrations with AWS CodePipeline, the expected sequence varies from the standard API user. In order to integrate with AWS CodePipeline, developers will need to work with the following items:</p> <p> <b>Jobs</b>, which are instances of an action. For example, a job for a source action might import a revision of an artifact from a source. </p> <p>You can work with jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeJob</a>, which confirms whether a job worker has received the specified job,</p> </li> <li> <p> <a>GetJobDetails</a>, which returns the details of a job,</p> </li> <li> <p> <a>PollForJobs</a>, which determines whether there are any jobs to act upon, </p> </li> <li> <p> <a>PutJobFailureResult</a>, which provides details of a job failure, and</p> </li> <li> <p> <a>PutJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul> <p> <b>Third party jobs</b>, which are instances of an action created by a partner action and integrated into AWS CodePipeline. Partner actions are created by members of the AWS Partner Network.</p> <p>You can work with third party jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeThirdPartyJob</a>, which confirms whether a job worker has received the specified job,</p> </li> <li> <p> <a>GetThirdPartyJobDetails</a>, which requests the details of a job for a partner action,</p> </li> <li> <p> <a>PollForThirdPartyJobs</a>, which determines whether there are any jobs to act upon, </p> </li> <li> <p> <a>PutThirdPartyJobFailureResult</a>, which provides details of a job failure, and</p> </li> <li> <p> <a>PutThirdPartyJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codepipeline/
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcknowledgeJob_600768 = ref object of OpenApiRestCall_600426
proc url_AcknowledgeJob_600770(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcknowledgeJob_600769(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about a specified job and whether that job has been received by the job worker. Only used for custom actions.
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AcknowledgeJob_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Only used for custom actions.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AcknowledgeJob_600768; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Only used for custom actions.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var acknowledgeJob* = Call_AcknowledgeJob_600768(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_600769, base: "/", url: url_AcknowledgeJob_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_601037 = ref object of OpenApiRestCall_600426
proc url_AcknowledgeThirdPartyJob_601039(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcknowledgeThirdPartyJob_601038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Confirms a job worker has received the specified job. Only used for partner actions.
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
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_AcknowledgeThirdPartyJob_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms a job worker has received the specified job. Only used for partner actions.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_AcknowledgeThirdPartyJob_601037; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Only used for partner actions.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_601037(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_601038, base: "/",
    url: url_AcknowledgeThirdPartyJob_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_601052 = ref object of OpenApiRestCall_600426
proc url_CreateCustomActionType_601054(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCustomActionType_601053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateCustomActionType_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateCustomActionType_601052; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createCustomActionType* = Call_CreateCustomActionType_601052(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_601053, base: "/",
    url: url_CreateCustomActionType_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_601067 = ref object of OpenApiRestCall_600426
proc url_CreatePipeline_601069(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePipeline_601068(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreatePipeline_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreatePipeline_601067; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createPipeline* = Call_CreatePipeline_601067(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_601068, base: "/", url: url_CreatePipeline_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteCustomActionType_601084(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCustomActionType_601083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action will fail after the action is marked for deletion. Only used for custom actions.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteCustomActionType_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action will fail after the action is marked for deletion. Only used for custom actions.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteCustomActionType_601082; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action will fail after the action is marked for deletion. Only used for custom actions.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteCustomActionType* = Call_DeleteCustomActionType_601082(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_601083, base: "/",
    url: url_DeleteCustomActionType_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_601097 = ref object of OpenApiRestCall_600426
proc url_DeletePipeline_601099(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePipeline_601098(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeletePipeline_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeletePipeline_601097; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deletePipeline* = Call_DeletePipeline_601097(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_601098, base: "/", url: url_DeletePipeline_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_601112 = ref object of OpenApiRestCall_600426
proc url_DeleteWebhook_601114(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteWebhook_601113(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API will return successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
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
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DeleteWebhook_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API will return successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeleteWebhook_601112; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API will return successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deleteWebhook* = Call_DeleteWebhook_601112(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_601113, base: "/", url: url_DeleteWebhook_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_601127 = ref object of OpenApiRestCall_600426
proc url_DeregisterWebhookWithThirdParty_601129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterWebhookWithThirdParty_601128(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently only supported for webhooks that target an action type of GitHub.
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
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeregisterWebhookWithThirdParty_601127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently only supported for webhooks that target an action type of GitHub.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeregisterWebhookWithThirdParty_601127; body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently only supported for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_601127(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_601128, base: "/",
    url: url_DeregisterWebhookWithThirdParty_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_601142 = ref object of OpenApiRestCall_600426
proc url_DisableStageTransition_601144(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableStageTransition_601143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DisableStageTransition_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DisableStageTransition_601142; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var disableStageTransition* = Call_DisableStageTransition_601142(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_601143, base: "/",
    url: url_DisableStageTransition_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_601157 = ref object of OpenApiRestCall_600426
proc url_EnableStageTransition_601159(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableStageTransition_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_EnableStageTransition_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_EnableStageTransition_601157; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var enableStageTransition* = Call_EnableStageTransition_601157(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_601158, base: "/",
    url: url_EnableStageTransition_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_601172 = ref object of OpenApiRestCall_600426
proc url_GetJobDetails_601174(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobDetails_601173(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a job. Only used for custom actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
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
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_GetJobDetails_601172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a job. Only used for custom actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_GetJobDetails_601172; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Only used for custom actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var getJobDetails* = Call_GetJobDetails_601172(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_601173, base: "/", url: url_GetJobDetails_601174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_601187 = ref object of OpenApiRestCall_600426
proc url_GetPipeline_601189(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPipeline_601188(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_GetPipeline_601187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_GetPipeline_601187; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var getPipeline* = Call_GetPipeline_601187(name: "getPipeline",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
                                        validator: validate_GetPipeline_601188,
                                        base: "/", url: url_GetPipeline_601189,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_601202 = ref object of OpenApiRestCall_600426
proc url_GetPipelineExecution_601204(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPipelineExecution_601203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_GetPipelineExecution_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_GetPipelineExecution_601202; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var getPipelineExecution* = Call_GetPipelineExecution_601202(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_601203, base: "/",
    url: url_GetPipelineExecution_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_601217 = ref object of OpenApiRestCall_600426
proc url_GetPipelineState_601219(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPipelineState_601218(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_GetPipelineState_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_GetPipelineState_601217; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var getPipelineState* = Call_GetPipelineState_601217(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_601218, base: "/",
    url: url_GetPipelineState_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_601232 = ref object of OpenApiRestCall_600426
proc url_GetThirdPartyJobDetails_601234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetThirdPartyJobDetails_601233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Requests the details of a job for a third party action. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
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
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_GetThirdPartyJobDetails_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests the details of a job for a third party action. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_GetThirdPartyJobDetails_601232; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_601232(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_601233, base: "/",
    url: url_GetThirdPartyJobDetails_601234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_601247 = ref object of OpenApiRestCall_600426
proc url_ListActionExecutions_601249(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListActionExecutions_601248(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601250 = query.getOrDefault("maxResults")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "maxResults", valid_601250
  var valid_601251 = query.getOrDefault("nextToken")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "nextToken", valid_601251
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
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601254 = header.getOrDefault("X-Amz-Target")
  valid_601254 = validateParameter(valid_601254, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionExecutions"))
  if valid_601254 != nil:
    section.add "X-Amz-Target", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Content-Sha256", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Algorithm")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Algorithm", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Signature")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Signature", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-SignedHeaders", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Credential")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Credential", valid_601259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601261: Call_ListActionExecutions_601247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_601261.validator(path, query, header, formData, body)
  let scheme = call_601261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601261.url(scheme.get, call_601261.host, call_601261.base,
                         call_601261.route, valid.getOrDefault("path"))
  result = hook(call_601261, url, valid)

proc call*(call_601262: Call_ListActionExecutions_601247; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601263 = newJObject()
  var body_601264 = newJObject()
  add(query_601263, "maxResults", newJString(maxResults))
  add(query_601263, "nextToken", newJString(nextToken))
  if body != nil:
    body_601264 = body
  result = call_601262.call(nil, query_601263, nil, nil, body_601264)

var listActionExecutions* = Call_ListActionExecutions_601247(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_601248, base: "/",
    url: url_ListActionExecutions_601249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_601266 = ref object of OpenApiRestCall_600426
proc url_ListActionTypes_601268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListActionTypes_601267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601269 = query.getOrDefault("nextToken")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "nextToken", valid_601269
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
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601272 = header.getOrDefault("X-Amz-Target")
  valid_601272 = validateParameter(valid_601272, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_601272 != nil:
    section.add "X-Amz-Target", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Content-Sha256", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Algorithm")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Algorithm", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Signature")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Signature", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-SignedHeaders", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Credential")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Credential", valid_601277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601279: Call_ListActionTypes_601266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_601279.validator(path, query, header, formData, body)
  let scheme = call_601279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601279.url(scheme.get, call_601279.host, call_601279.base,
                         call_601279.route, valid.getOrDefault("path"))
  result = hook(call_601279, url, valid)

proc call*(call_601280: Call_ListActionTypes_601266; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601281 = newJObject()
  var body_601282 = newJObject()
  add(query_601281, "nextToken", newJString(nextToken))
  if body != nil:
    body_601282 = body
  result = call_601280.call(nil, query_601281, nil, nil, body_601282)

var listActionTypes* = Call_ListActionTypes_601266(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_601267, base: "/", url: url_ListActionTypes_601268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_601283 = ref object of OpenApiRestCall_600426
proc url_ListPipelineExecutions_601285(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPipelineExecutions_601284(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601286 = query.getOrDefault("maxResults")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "maxResults", valid_601286
  var valid_601287 = query.getOrDefault("nextToken")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "nextToken", valid_601287
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
  var valid_601288 = header.getOrDefault("X-Amz-Date")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Date", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Security-Token")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Security-Token", valid_601289
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601290 = header.getOrDefault("X-Amz-Target")
  valid_601290 = validateParameter(valid_601290, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_601290 != nil:
    section.add "X-Amz-Target", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Content-Sha256", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Algorithm")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Algorithm", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Signature")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Signature", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-SignedHeaders", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Credential")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Credential", valid_601295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601297: Call_ListPipelineExecutions_601283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_601297.validator(path, query, header, formData, body)
  let scheme = call_601297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601297.url(scheme.get, call_601297.host, call_601297.base,
                         call_601297.route, valid.getOrDefault("path"))
  result = hook(call_601297, url, valid)

proc call*(call_601298: Call_ListPipelineExecutions_601283; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601299 = newJObject()
  var body_601300 = newJObject()
  add(query_601299, "maxResults", newJString(maxResults))
  add(query_601299, "nextToken", newJString(nextToken))
  if body != nil:
    body_601300 = body
  result = call_601298.call(nil, query_601299, nil, nil, body_601300)

var listPipelineExecutions* = Call_ListPipelineExecutions_601283(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_601284, base: "/",
    url: url_ListPipelineExecutions_601285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_601301 = ref object of OpenApiRestCall_600426
proc url_ListPipelines_601303(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPipelines_601302(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601304 = query.getOrDefault("nextToken")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "nextToken", valid_601304
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
  var valid_601305 = header.getOrDefault("X-Amz-Date")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Date", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Security-Token")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Security-Token", valid_601306
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601307 = header.getOrDefault("X-Amz-Target")
  valid_601307 = validateParameter(valid_601307, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_601307 != nil:
    section.add "X-Amz-Target", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601314: Call_ListPipelines_601301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_601314.validator(path, query, header, formData, body)
  let scheme = call_601314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601314.url(scheme.get, call_601314.host, call_601314.base,
                         call_601314.route, valid.getOrDefault("path"))
  result = hook(call_601314, url, valid)

proc call*(call_601315: Call_ListPipelines_601301; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601316 = newJObject()
  var body_601317 = newJObject()
  add(query_601316, "nextToken", newJString(nextToken))
  if body != nil:
    body_601317 = body
  result = call_601315.call(nil, query_601316, nil, nil, body_601317)

var listPipelines* = Call_ListPipelines_601301(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_601302, base: "/", url: url_ListPipelines_601303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601318 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601320(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601319(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the set of key/value pairs (metadata) that are used to manage the resource.
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
  var valid_601321 = query.getOrDefault("maxResults")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "maxResults", valid_601321
  var valid_601322 = query.getOrDefault("nextToken")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "nextToken", valid_601322
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
  var valid_601323 = header.getOrDefault("X-Amz-Date")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Date", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Security-Token")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Security-Token", valid_601324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601325 = header.getOrDefault("X-Amz-Target")
  valid_601325 = validateParameter(valid_601325, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_601325 != nil:
    section.add "X-Amz-Target", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Content-Sha256", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Algorithm")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Algorithm", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Signature")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Signature", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-SignedHeaders", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Credential")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Credential", valid_601330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_ListTagsForResource_601318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the set of key/value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_ListTagsForResource_601318; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key/value pairs (metadata) that are used to manage the resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601334 = newJObject()
  var body_601335 = newJObject()
  add(query_601334, "maxResults", newJString(maxResults))
  add(query_601334, "nextToken", newJString(nextToken))
  if body != nil:
    body_601335 = body
  result = call_601333.call(nil, query_601334, nil, nil, body_601335)

var listTagsForResource* = Call_ListTagsForResource_601318(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_601319, base: "/",
    url: url_ListTagsForResource_601320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_601336 = ref object of OpenApiRestCall_600426
proc url_ListWebhooks_601338(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWebhooks_601337(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a listing of all the webhooks in this region for this account. The output lists all webhooks and includes the webhook URL and ARN, as well the configuration for each webhook.
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
  var valid_601339 = query.getOrDefault("NextToken")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "NextToken", valid_601339
  var valid_601340 = query.getOrDefault("MaxResults")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "MaxResults", valid_601340
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
  var valid_601341 = header.getOrDefault("X-Amz-Date")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Date", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Security-Token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Security-Token", valid_601342
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601343 = header.getOrDefault("X-Amz-Target")
  valid_601343 = validateParameter(valid_601343, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_601343 != nil:
    section.add "X-Amz-Target", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_ListWebhooks_601336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a listing of all the webhooks in this region for this account. The output lists all webhooks and includes the webhook URL and ARN, as well the configuration for each webhook.
  ## 
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"))
  result = hook(call_601350, url, valid)

proc call*(call_601351: Call_ListWebhooks_601336; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this region for this account. The output lists all webhooks and includes the webhook URL and ARN, as well the configuration for each webhook.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601352 = newJObject()
  var body_601353 = newJObject()
  add(query_601352, "NextToken", newJString(NextToken))
  if body != nil:
    body_601353 = body
  add(query_601352, "MaxResults", newJString(MaxResults))
  result = call_601351.call(nil, query_601352, nil, nil, body_601353)

var listWebhooks* = Call_ListWebhooks_601336(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_601337, base: "/", url: url_ListWebhooks_601338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_601354 = ref object of OpenApiRestCall_600426
proc url_PollForJobs_601356(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PollForJobs_601355(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about any jobs for AWS CodePipeline to act upon. <code>PollForJobs</code> is only valid for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
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
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601359 = header.getOrDefault("X-Amz-Target")
  valid_601359 = validateParameter(valid_601359, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_601359 != nil:
    section.add "X-Amz-Target", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Content-Sha256", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Algorithm")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Algorithm", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Signature")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Signature", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-SignedHeaders", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Credential")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Credential", valid_601364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_PollForJobs_601354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act upon. <code>PollForJobs</code> is only valid for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"))
  result = hook(call_601366, url, valid)

proc call*(call_601367: Call_PollForJobs_601354; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act upon. <code>PollForJobs</code> is only valid for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. Additionally, this API returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_601368 = newJObject()
  if body != nil:
    body_601368 = body
  result = call_601367.call(nil, nil, nil, nil, body_601368)

var pollForJobs* = Call_PollForJobs_601354(name: "pollForJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
                                        validator: validate_PollForJobs_601355,
                                        base: "/", url: url_PollForJobs_601356,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_601369 = ref object of OpenApiRestCall_600426
proc url_PollForThirdPartyJobs_601371(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PollForThirdPartyJobs_601370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
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
  var valid_601372 = header.getOrDefault("X-Amz-Date")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Date", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Security-Token")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Security-Token", valid_601373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601374 = header.getOrDefault("X-Amz-Target")
  valid_601374 = validateParameter(valid_601374, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_601374 != nil:
    section.add "X-Amz-Target", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Content-Sha256", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Algorithm")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Algorithm", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Signature")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Signature", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-SignedHeaders", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Credential")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Credential", valid_601379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601381: Call_PollForThirdPartyJobs_601369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_601381.validator(path, query, header, formData, body)
  let scheme = call_601381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601381.url(scheme.get, call_601381.host, call_601381.base,
                         call_601381.route, valid.getOrDefault("path"))
  result = hook(call_601381, url, valid)

proc call*(call_601382: Call_PollForThirdPartyJobs_601369; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Only used for partner actions.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_601383 = newJObject()
  if body != nil:
    body_601383 = body
  result = call_601382.call(nil, nil, nil, nil, body_601383)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_601369(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_601370, base: "/",
    url: url_PollForThirdPartyJobs_601371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_601384 = ref object of OpenApiRestCall_600426
proc url_PutActionRevision_601386(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutActionRevision_601385(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601387 = header.getOrDefault("X-Amz-Date")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Date", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Security-Token")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Security-Token", valid_601388
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601389 = header.getOrDefault("X-Amz-Target")
  valid_601389 = validateParameter(valid_601389, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_601389 != nil:
    section.add "X-Amz-Target", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Content-Sha256", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Algorithm")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Algorithm", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Signature")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Signature", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-SignedHeaders", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Credential")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Credential", valid_601394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601396: Call_PutActionRevision_601384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_601396.validator(path, query, header, formData, body)
  let scheme = call_601396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601396.url(scheme.get, call_601396.host, call_601396.base,
                         call_601396.route, valid.getOrDefault("path"))
  result = hook(call_601396, url, valid)

proc call*(call_601397: Call_PutActionRevision_601384; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_601398 = newJObject()
  if body != nil:
    body_601398 = body
  result = call_601397.call(nil, nil, nil, nil, body_601398)

var putActionRevision* = Call_PutActionRevision_601384(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_601385, base: "/",
    url: url_PutActionRevision_601386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_601399 = ref object of OpenApiRestCall_600426
proc url_PutApprovalResult_601401(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutApprovalResult_601400(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601402 = header.getOrDefault("X-Amz-Date")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Date", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Security-Token")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Security-Token", valid_601403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601404 = header.getOrDefault("X-Amz-Target")
  valid_601404 = validateParameter(valid_601404, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_601404 != nil:
    section.add "X-Amz-Target", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Content-Sha256", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Algorithm")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Algorithm", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Signature")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Signature", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-SignedHeaders", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Credential")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Credential", valid_601409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601411: Call_PutApprovalResult_601399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_601411.validator(path, query, header, formData, body)
  let scheme = call_601411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601411.url(scheme.get, call_601411.host, call_601411.base,
                         call_601411.route, valid.getOrDefault("path"))
  result = hook(call_601411, url, valid)

proc call*(call_601412: Call_PutApprovalResult_601399; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_601413 = newJObject()
  if body != nil:
    body_601413 = body
  result = call_601412.call(nil, nil, nil, nil, body_601413)

var putApprovalResult* = Call_PutApprovalResult_601399(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_601400, base: "/",
    url: url_PutApprovalResult_601401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_601414 = ref object of OpenApiRestCall_600426
proc url_PutJobFailureResult_601416(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutJobFailureResult_601415(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Only used for custom actions.
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
  var valid_601417 = header.getOrDefault("X-Amz-Date")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Date", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Security-Token")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Security-Token", valid_601418
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601419 = header.getOrDefault("X-Amz-Target")
  valid_601419 = validateParameter(valid_601419, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_601419 != nil:
    section.add "X-Amz-Target", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Content-Sha256", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Algorithm")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Algorithm", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Signature")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Signature", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-SignedHeaders", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Credential")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Credential", valid_601424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601426: Call_PutJobFailureResult_601414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Only used for custom actions.
  ## 
  let valid = call_601426.validator(path, query, header, formData, body)
  let scheme = call_601426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601426.url(scheme.get, call_601426.host, call_601426.base,
                         call_601426.route, valid.getOrDefault("path"))
  result = hook(call_601426, url, valid)

proc call*(call_601427: Call_PutJobFailureResult_601414; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Only used for custom actions.
  ##   body: JObject (required)
  var body_601428 = newJObject()
  if body != nil:
    body_601428 = body
  result = call_601427.call(nil, nil, nil, nil, body_601428)

var putJobFailureResult* = Call_PutJobFailureResult_601414(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_601415, base: "/",
    url: url_PutJobFailureResult_601416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_601429 = ref object of OpenApiRestCall_600426
proc url_PutJobSuccessResult_601431(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutJobSuccessResult_601430(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Represents the success of a job as returned to the pipeline by a job worker. Only used for custom actions.
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
  var valid_601432 = header.getOrDefault("X-Amz-Date")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Date", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Security-Token")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Security-Token", valid_601433
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601434 = header.getOrDefault("X-Amz-Target")
  valid_601434 = validateParameter(valid_601434, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_601434 != nil:
    section.add "X-Amz-Target", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Content-Sha256", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Algorithm")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Algorithm", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Signature")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Signature", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-SignedHeaders", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Credential")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Credential", valid_601439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601441: Call_PutJobSuccessResult_601429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Only used for custom actions.
  ## 
  let valid = call_601441.validator(path, query, header, formData, body)
  let scheme = call_601441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601441.url(scheme.get, call_601441.host, call_601441.base,
                         call_601441.route, valid.getOrDefault("path"))
  result = hook(call_601441, url, valid)

proc call*(call_601442: Call_PutJobSuccessResult_601429; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Only used for custom actions.
  ##   body: JObject (required)
  var body_601443 = newJObject()
  if body != nil:
    body_601443 = body
  result = call_601442.call(nil, nil, nil, nil, body_601443)

var putJobSuccessResult* = Call_PutJobSuccessResult_601429(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_601430, base: "/",
    url: url_PutJobSuccessResult_601431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_601444 = ref object of OpenApiRestCall_600426
proc url_PutThirdPartyJobFailureResult_601446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutThirdPartyJobFailureResult_601445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
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
  var valid_601447 = header.getOrDefault("X-Amz-Date")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Date", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Security-Token")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Security-Token", valid_601448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601449 = header.getOrDefault("X-Amz-Target")
  valid_601449 = validateParameter(valid_601449, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_601449 != nil:
    section.add "X-Amz-Target", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Content-Sha256", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Algorithm")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Algorithm", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Signature")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Signature", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-SignedHeaders", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Credential")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Credential", valid_601454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601456: Call_PutThirdPartyJobFailureResult_601444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
  ## 
  let valid = call_601456.validator(path, query, header, formData, body)
  let scheme = call_601456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601456.url(scheme.get, call_601456.host, call_601456.base,
                         call_601456.route, valid.getOrDefault("path"))
  result = hook(call_601456, url, valid)

proc call*(call_601457: Call_PutThirdPartyJobFailureResult_601444; body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
  ##   body: JObject (required)
  var body_601458 = newJObject()
  if body != nil:
    body_601458 = body
  result = call_601457.call(nil, nil, nil, nil, body_601458)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_601444(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_601445, base: "/",
    url: url_PutThirdPartyJobFailureResult_601446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_601459 = ref object of OpenApiRestCall_600426
proc url_PutThirdPartyJobSuccessResult_601461(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutThirdPartyJobSuccessResult_601460(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
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
  var valid_601462 = header.getOrDefault("X-Amz-Date")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Date", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Security-Token")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Security-Token", valid_601463
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601464 = header.getOrDefault("X-Amz-Target")
  valid_601464 = validateParameter(valid_601464, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_601464 != nil:
    section.add "X-Amz-Target", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Content-Sha256", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Algorithm")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Algorithm", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Signature")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Signature", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-SignedHeaders", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Credential")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Credential", valid_601469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601471: Call_PutThirdPartyJobSuccessResult_601459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
  ## 
  let valid = call_601471.validator(path, query, header, formData, body)
  let scheme = call_601471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601471.url(scheme.get, call_601471.host, call_601471.base,
                         call_601471.route, valid.getOrDefault("path"))
  result = hook(call_601471, url, valid)

proc call*(call_601472: Call_PutThirdPartyJobSuccessResult_601459; body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Only used for partner actions.
  ##   body: JObject (required)
  var body_601473 = newJObject()
  if body != nil:
    body_601473 = body
  result = call_601472.call(nil, nil, nil, nil, body_601473)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_601459(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_601460, base: "/",
    url: url_PutThirdPartyJobSuccessResult_601461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_601474 = ref object of OpenApiRestCall_600426
proc url_PutWebhook_601476(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutWebhook_601475(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601477 = header.getOrDefault("X-Amz-Date")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Date", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Security-Token")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Security-Token", valid_601478
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601479 = header.getOrDefault("X-Amz-Target")
  valid_601479 = validateParameter(valid_601479, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_601479 != nil:
    section.add "X-Amz-Target", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Content-Sha256", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Algorithm")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Algorithm", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Signature")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Signature", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-SignedHeaders", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Credential")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Credential", valid_601484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601486: Call_PutWebhook_601474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_601486.validator(path, query, header, formData, body)
  let scheme = call_601486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601486.url(scheme.get, call_601486.host, call_601486.base,
                         call_601486.route, valid.getOrDefault("path"))
  result = hook(call_601486, url, valid)

proc call*(call_601487: Call_PutWebhook_601474; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_601488 = newJObject()
  if body != nil:
    body_601488 = body
  result = call_601487.call(nil, nil, nil, nil, body_601488)

var putWebhook* = Call_PutWebhook_601474(name: "putWebhook",
                                      meth: HttpMethod.HttpPost,
                                      host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                      validator: validate_PutWebhook_601475,
                                      base: "/", url: url_PutWebhook_601476,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_601489 = ref object of OpenApiRestCall_600426
proc url_RegisterWebhookWithThirdParty_601491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterWebhookWithThirdParty_601490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601492 = header.getOrDefault("X-Amz-Date")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Date", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Security-Token")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Security-Token", valid_601493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601494 = header.getOrDefault("X-Amz-Target")
  valid_601494 = validateParameter(valid_601494, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_601494 != nil:
    section.add "X-Amz-Target", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Content-Sha256", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Algorithm")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Algorithm", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Signature")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Signature", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-SignedHeaders", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Credential")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Credential", valid_601499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601501: Call_RegisterWebhookWithThirdParty_601489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_601501.validator(path, query, header, formData, body)
  let scheme = call_601501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601501.url(scheme.get, call_601501.host, call_601501.base,
                         call_601501.route, valid.getOrDefault("path"))
  result = hook(call_601501, url, valid)

proc call*(call_601502: Call_RegisterWebhookWithThirdParty_601489; body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_601503 = newJObject()
  if body != nil:
    body_601503 = body
  result = call_601502.call(nil, nil, nil, nil, body_601503)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_601489(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_601490, base: "/",
    url: url_RegisterWebhookWithThirdParty_601491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_601504 = ref object of OpenApiRestCall_600426
proc url_RetryStageExecution_601506(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RetryStageExecution_601505(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage.
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
  var valid_601507 = header.getOrDefault("X-Amz-Date")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Date", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Security-Token")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Security-Token", valid_601508
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601509 = header.getOrDefault("X-Amz-Target")
  valid_601509 = validateParameter(valid_601509, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_601509 != nil:
    section.add "X-Amz-Target", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Content-Sha256", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Algorithm")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Algorithm", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Signature")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Signature", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-SignedHeaders", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Credential")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Credential", valid_601514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601516: Call_RetryStageExecution_601504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage.
  ## 
  let valid = call_601516.validator(path, query, header, formData, body)
  let scheme = call_601516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601516.url(scheme.get, call_601516.host, call_601516.base,
                         call_601516.route, valid.getOrDefault("path"))
  result = hook(call_601516, url, valid)

proc call*(call_601517: Call_RetryStageExecution_601504; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage.
  ##   body: JObject (required)
  var body_601518 = newJObject()
  if body != nil:
    body_601518 = body
  result = call_601517.call(nil, nil, nil, nil, body_601518)

var retryStageExecution* = Call_RetryStageExecution_601504(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_601505, base: "/",
    url: url_RetryStageExecution_601506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_601519 = ref object of OpenApiRestCall_600426
proc url_StartPipelineExecution_601521(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartPipelineExecution_601520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601522 = header.getOrDefault("X-Amz-Date")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Date", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Security-Token")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Security-Token", valid_601523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601524 = header.getOrDefault("X-Amz-Target")
  valid_601524 = validateParameter(valid_601524, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_601524 != nil:
    section.add "X-Amz-Target", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Content-Sha256", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-Algorithm")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Algorithm", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Signature")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Signature", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-SignedHeaders", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Credential")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Credential", valid_601529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601531: Call_StartPipelineExecution_601519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_601531.validator(path, query, header, formData, body)
  let scheme = call_601531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601531.url(scheme.get, call_601531.host, call_601531.base,
                         call_601531.route, valid.getOrDefault("path"))
  result = hook(call_601531, url, valid)

proc call*(call_601532: Call_StartPipelineExecution_601519; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_601533 = newJObject()
  if body != nil:
    body_601533 = body
  result = call_601532.call(nil, nil, nil, nil, body_601533)

var startPipelineExecution* = Call_StartPipelineExecution_601519(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_601520, base: "/",
    url: url_StartPipelineExecution_601521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601534 = ref object of OpenApiRestCall_600426
proc url_TagResource_601536(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601535(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601537 = header.getOrDefault("X-Amz-Date")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Date", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Security-Token")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Security-Token", valid_601538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601539 = header.getOrDefault("X-Amz-Target")
  valid_601539 = validateParameter(valid_601539, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_601539 != nil:
    section.add "X-Amz-Target", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Content-Sha256", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Algorithm")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Algorithm", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Signature")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Signature", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-SignedHeaders", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Credential")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Credential", valid_601544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601546: Call_TagResource_601534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_601546.validator(path, query, header, formData, body)
  let scheme = call_601546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601546.url(scheme.get, call_601546.host, call_601546.base,
                         call_601546.route, valid.getOrDefault("path"))
  result = hook(call_601546, url, valid)

proc call*(call_601547: Call_TagResource_601534; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_601548 = newJObject()
  if body != nil:
    body_601548 = body
  result = call_601547.call(nil, nil, nil, nil, body_601548)

var tagResource* = Call_TagResource_601534(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
                                        validator: validate_TagResource_601535,
                                        base: "/", url: url_TagResource_601536,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601549 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601551(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601550(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601552 = header.getOrDefault("X-Amz-Date")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Date", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Security-Token")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Security-Token", valid_601553
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601554 = header.getOrDefault("X-Amz-Target")
  valid_601554 = validateParameter(valid_601554, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_601554 != nil:
    section.add "X-Amz-Target", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Content-Sha256", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Algorithm")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Algorithm", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Signature")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Signature", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-SignedHeaders", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Credential")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Credential", valid_601559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601561: Call_UntagResource_601549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_601561.validator(path, query, header, formData, body)
  let scheme = call_601561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601561.url(scheme.get, call_601561.host, call_601561.base,
                         call_601561.route, valid.getOrDefault("path"))
  result = hook(call_601561, url, valid)

proc call*(call_601562: Call_UntagResource_601549; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_601563 = newJObject()
  if body != nil:
    body_601563 = body
  result = call_601562.call(nil, nil, nil, nil, body_601563)

var untagResource* = Call_UntagResource_601549(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_601550, base: "/", url: url_UntagResource_601551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_601564 = ref object of OpenApiRestCall_600426
proc url_UpdatePipeline_601566(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePipeline_601565(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure in conjunction with <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
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
  var valid_601567 = header.getOrDefault("X-Amz-Date")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Date", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Security-Token")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Security-Token", valid_601568
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601569 = header.getOrDefault("X-Amz-Target")
  valid_601569 = validateParameter(valid_601569, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_601569 != nil:
    section.add "X-Amz-Target", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Content-Sha256", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Algorithm")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Algorithm", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Signature")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Signature", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-SignedHeaders", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Credential")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Credential", valid_601574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601576: Call_UpdatePipeline_601564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure in conjunction with <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_601576.validator(path, query, header, formData, body)
  let scheme = call_601576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601576.url(scheme.get, call_601576.host, call_601576.base,
                         call_601576.route, valid.getOrDefault("path"))
  result = hook(call_601576, url, valid)

proc call*(call_601577: Call_UpdatePipeline_601564; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure in conjunction with <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_601578 = newJObject()
  if body != nil:
    body_601578 = body
  result = call_601577.call(nil, nil, nil, nil, body_601578)

var updatePipeline* = Call_UpdatePipeline_601564(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_601565, base: "/", url: url_UpdatePipeline_601566,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
