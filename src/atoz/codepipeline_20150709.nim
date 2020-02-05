
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcknowledgeJob_612996 = ref object of OpenApiRestCall_612658
proc url_AcknowledgeJob_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AcknowledgeJob_612997(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AcknowledgeJob_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AcknowledgeJob_612996; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var acknowledgeJob* = Call_AcknowledgeJob_612996(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_612997, base: "/", url: url_AcknowledgeJob_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_613265 = ref object of OpenApiRestCall_612658
proc url_AcknowledgeThirdPartyJob_613267(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_AcknowledgeThirdPartyJob_613266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_AcknowledgeThirdPartyJob_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AcknowledgeThirdPartyJob_613265; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_613265(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_613266, base: "/",
    url: url_AcknowledgeThirdPartyJob_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_613280 = ref object of OpenApiRestCall_612658
proc url_CreateCustomActionType_613282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomActionType_613281(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateCustomActionType_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateCustomActionType_613280; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createCustomActionType* = Call_CreateCustomActionType_613280(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_613281, base: "/",
    url: url_CreateCustomActionType_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_613295 = ref object of OpenApiRestCall_612658
proc url_CreatePipeline_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_613296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreatePipeline_613295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreatePipeline_613295; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createPipeline* = Call_CreatePipeline_613295(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_613296, base: "/", url: url_CreatePipeline_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_613310 = ref object of OpenApiRestCall_612658
proc url_DeleteCustomActionType_613312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomActionType_613311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_DeleteCustomActionType_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_DeleteCustomActionType_613310; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var deleteCustomActionType* = Call_DeleteCustomActionType_613310(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_613311, base: "/",
    url: url_DeleteCustomActionType_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_613325 = ref object of OpenApiRestCall_612658
proc url_DeletePipeline_613327(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_613326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DeletePipeline_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DeletePipeline_613325; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var deletePipeline* = Call_DeletePipeline_613325(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_613326, base: "/", url: url_DeletePipeline_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_613340 = ref object of OpenApiRestCall_612658
proc url_DeleteWebhook_613342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_613341(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DeleteWebhook_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DeleteWebhook_613340; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var deleteWebhook* = Call_DeleteWebhook_613340(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_613341, base: "/", url: url_DeleteWebhook_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_613355 = ref object of OpenApiRestCall_612658
proc url_DeregisterWebhookWithThirdParty_613357(protocol: Scheme; host: string;
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

proc validate_DeregisterWebhookWithThirdParty_613356(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DeregisterWebhookWithThirdParty_613355;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DeregisterWebhookWithThirdParty_613355; body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_613355(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_613356, base: "/",
    url: url_DeregisterWebhookWithThirdParty_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_613370 = ref object of OpenApiRestCall_612658
proc url_DisableStageTransition_613372(protocol: Scheme; host: string; base: string;
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

proc validate_DisableStageTransition_613371(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_DisableStageTransition_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_DisableStageTransition_613370; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var disableStageTransition* = Call_DisableStageTransition_613370(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_613371, base: "/",
    url: url_DisableStageTransition_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_613385 = ref object of OpenApiRestCall_612658
proc url_EnableStageTransition_613387(protocol: Scheme; host: string; base: string;
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

proc validate_EnableStageTransition_613386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_EnableStageTransition_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_EnableStageTransition_613385; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var enableStageTransition* = Call_EnableStageTransition_613385(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_613386, base: "/",
    url: url_EnableStageTransition_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_613400 = ref object of OpenApiRestCall_612658
proc url_GetJobDetails_613402(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobDetails_613401(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_GetJobDetails_613400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_GetJobDetails_613400; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var getJobDetails* = Call_GetJobDetails_613400(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_613401, base: "/", url: url_GetJobDetails_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_613415 = ref object of OpenApiRestCall_612658
proc url_GetPipeline_613417(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipeline_613416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_GetPipeline_613415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_GetPipeline_613415; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var getPipeline* = Call_GetPipeline_613415(name: "getPipeline",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
                                        validator: validate_GetPipeline_613416,
                                        base: "/", url: url_GetPipeline_613417,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_613430 = ref object of OpenApiRestCall_612658
proc url_GetPipelineExecution_613432(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipelineExecution_613431(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_GetPipelineExecution_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_GetPipelineExecution_613430; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var getPipelineExecution* = Call_GetPipelineExecution_613430(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_613431, base: "/",
    url: url_GetPipelineExecution_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_613445 = ref object of OpenApiRestCall_612658
proc url_GetPipelineState_613447(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipelineState_613446(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_GetPipelineState_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_GetPipelineState_613445; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var getPipelineState* = Call_GetPipelineState_613445(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_613446, base: "/",
    url: url_GetPipelineState_613447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_613460 = ref object of OpenApiRestCall_612658
proc url_GetThirdPartyJobDetails_613462(protocol: Scheme; host: string; base: string;
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

proc validate_GetThirdPartyJobDetails_613461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_GetThirdPartyJobDetails_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_GetThirdPartyJobDetails_613460; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_613460(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_613461, base: "/",
    url: url_GetThirdPartyJobDetails_613462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_613475 = ref object of OpenApiRestCall_612658
proc url_ListActionExecutions_613477(protocol: Scheme; host: string; base: string;
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

proc validate_ListActionExecutions_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613478 = query.getOrDefault("nextToken")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "nextToken", valid_613478
  var valid_613479 = query.getOrDefault("maxResults")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "maxResults", valid_613479
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
  var valid_613480 = header.getOrDefault("X-Amz-Target")
  valid_613480 = validateParameter(valid_613480, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionExecutions"))
  if valid_613480 != nil:
    section.add "X-Amz-Target", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Signature")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Signature", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Content-Sha256", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Date")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Date", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Credential")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Credential", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613489: Call_ListActionExecutions_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_613489.validator(path, query, header, formData, body)
  let scheme = call_613489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613489.url(scheme.get, call_613489.host, call_613489.base,
                         call_613489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613489, url, valid)

proc call*(call_613490: Call_ListActionExecutions_613475; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613491 = newJObject()
  var body_613492 = newJObject()
  add(query_613491, "nextToken", newJString(nextToken))
  if body != nil:
    body_613492 = body
  add(query_613491, "maxResults", newJString(maxResults))
  result = call_613490.call(nil, query_613491, nil, nil, body_613492)

var listActionExecutions* = Call_ListActionExecutions_613475(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_613476, base: "/",
    url: url_ListActionExecutions_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_613494 = ref object of OpenApiRestCall_612658
proc url_ListActionTypes_613496(protocol: Scheme; host: string; base: string;
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

proc validate_ListActionTypes_613495(path: JsonNode; query: JsonNode;
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
  var valid_613497 = query.getOrDefault("nextToken")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "nextToken", valid_613497
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
  var valid_613498 = header.getOrDefault("X-Amz-Target")
  valid_613498 = validateParameter(valid_613498, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_613498 != nil:
    section.add "X-Amz-Target", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Signature")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Signature", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Content-Sha256", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Date")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Date", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Credential")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Credential", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Security-Token")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Security-Token", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Algorithm")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Algorithm", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-SignedHeaders", valid_613505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613507: Call_ListActionTypes_613494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_613507.validator(path, query, header, formData, body)
  let scheme = call_613507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613507.url(scheme.get, call_613507.host, call_613507.base,
                         call_613507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613507, url, valid)

proc call*(call_613508: Call_ListActionTypes_613494; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613509 = newJObject()
  var body_613510 = newJObject()
  add(query_613509, "nextToken", newJString(nextToken))
  if body != nil:
    body_613510 = body
  result = call_613508.call(nil, query_613509, nil, nil, body_613510)

var listActionTypes* = Call_ListActionTypes_613494(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_613495, base: "/", url: url_ListActionTypes_613496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_613511 = ref object of OpenApiRestCall_612658
proc url_ListPipelineExecutions_613513(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelineExecutions_613512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613514 = query.getOrDefault("nextToken")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "nextToken", valid_613514
  var valid_613515 = query.getOrDefault("maxResults")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "maxResults", valid_613515
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
  var valid_613516 = header.getOrDefault("X-Amz-Target")
  valid_613516 = validateParameter(valid_613516, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_613516 != nil:
    section.add "X-Amz-Target", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Signature")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Signature", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Content-Sha256", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Date")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Date", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Credential")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Credential", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Security-Token")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Security-Token", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Algorithm")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Algorithm", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-SignedHeaders", valid_613523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613525: Call_ListPipelineExecutions_613511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_613525.validator(path, query, header, formData, body)
  let scheme = call_613525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613525.url(scheme.get, call_613525.host, call_613525.base,
                         call_613525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613525, url, valid)

proc call*(call_613526: Call_ListPipelineExecutions_613511; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613527 = newJObject()
  var body_613528 = newJObject()
  add(query_613527, "nextToken", newJString(nextToken))
  if body != nil:
    body_613528 = body
  add(query_613527, "maxResults", newJString(maxResults))
  result = call_613526.call(nil, query_613527, nil, nil, body_613528)

var listPipelineExecutions* = Call_ListPipelineExecutions_613511(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_613512, base: "/",
    url: url_ListPipelineExecutions_613513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_613529 = ref object of OpenApiRestCall_612658
proc url_ListPipelines_613531(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_613530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613532 = query.getOrDefault("nextToken")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "nextToken", valid_613532
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
  var valid_613533 = header.getOrDefault("X-Amz-Target")
  valid_613533 = validateParameter(valid_613533, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_613533 != nil:
    section.add "X-Amz-Target", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Signature")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Signature", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Content-Sha256", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Date")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Date", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Credential")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Credential", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Security-Token")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Security-Token", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Algorithm")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Algorithm", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-SignedHeaders", valid_613540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613542: Call_ListPipelines_613529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_613542.validator(path, query, header, formData, body)
  let scheme = call_613542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613542.url(scheme.get, call_613542.host, call_613542.base,
                         call_613542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613542, url, valid)

proc call*(call_613543: Call_ListPipelines_613529; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613544 = newJObject()
  var body_613545 = newJObject()
  add(query_613544, "nextToken", newJString(nextToken))
  if body != nil:
    body_613545 = body
  result = call_613543.call(nil, query_613544, nil, nil, body_613545)

var listPipelines* = Call_ListPipelines_613529(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_613530, base: "/", url: url_ListPipelines_613531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613546 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613548(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613547(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613549 = query.getOrDefault("nextToken")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "nextToken", valid_613549
  var valid_613550 = query.getOrDefault("maxResults")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "maxResults", valid_613550
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
  var valid_613551 = header.getOrDefault("X-Amz-Target")
  valid_613551 = validateParameter(valid_613551, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_613551 != nil:
    section.add "X-Amz-Target", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_ListTagsForResource_613546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_ListTagsForResource_613546; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613562 = newJObject()
  var body_613563 = newJObject()
  add(query_613562, "nextToken", newJString(nextToken))
  if body != nil:
    body_613563 = body
  add(query_613562, "maxResults", newJString(maxResults))
  result = call_613561.call(nil, query_613562, nil, nil, body_613563)

var listTagsForResource* = Call_ListTagsForResource_613546(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_613547, base: "/",
    url: url_ListTagsForResource_613548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_613564 = ref object of OpenApiRestCall_612658
proc url_ListWebhooks_613566(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_613565(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613567 = query.getOrDefault("MaxResults")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "MaxResults", valid_613567
  var valid_613568 = query.getOrDefault("NextToken")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "NextToken", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Target")
  valid_613569 = validateParameter(valid_613569, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_613569 != nil:
    section.add "X-Amz-Target", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Signature")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Signature", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Content-Sha256", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Date")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Date", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Credential")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Credential", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Security-Token")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Security-Token", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Algorithm")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Algorithm", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-SignedHeaders", valid_613576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613578: Call_ListWebhooks_613564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  let valid = call_613578.validator(path, query, header, formData, body)
  let scheme = call_613578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613578.url(scheme.get, call_613578.host, call_613578.base,
                         call_613578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613578, url, valid)

proc call*(call_613579: Call_ListWebhooks_613564; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613580 = newJObject()
  var body_613581 = newJObject()
  add(query_613580, "MaxResults", newJString(MaxResults))
  add(query_613580, "NextToken", newJString(NextToken))
  if body != nil:
    body_613581 = body
  result = call_613579.call(nil, query_613580, nil, nil, body_613581)

var listWebhooks* = Call_ListWebhooks_613564(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_613565, base: "/", url: url_ListWebhooks_613566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_613582 = ref object of OpenApiRestCall_612658
proc url_PollForJobs_613584(protocol: Scheme; host: string; base: string;
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

proc validate_PollForJobs_613583(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_613585 = header.getOrDefault("X-Amz-Target")
  valid_613585 = validateParameter(valid_613585, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_613585 != nil:
    section.add "X-Amz-Target", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Algorithm")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Algorithm", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-SignedHeaders", valid_613592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613594: Call_PollForJobs_613582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_613594.validator(path, query, header, formData, body)
  let scheme = call_613594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613594.url(scheme.get, call_613594.host, call_613594.base,
                         call_613594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613594, url, valid)

proc call*(call_613595: Call_PollForJobs_613582; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_613596 = newJObject()
  if body != nil:
    body_613596 = body
  result = call_613595.call(nil, nil, nil, nil, body_613596)

var pollForJobs* = Call_PollForJobs_613582(name: "pollForJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
                                        validator: validate_PollForJobs_613583,
                                        base: "/", url: url_PollForJobs_613584,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_613597 = ref object of OpenApiRestCall_612658
proc url_PollForThirdPartyJobs_613599(protocol: Scheme; host: string; base: string;
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

proc validate_PollForThirdPartyJobs_613598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
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
  var valid_613600 = header.getOrDefault("X-Amz-Target")
  valid_613600 = validateParameter(valid_613600, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_613600 != nil:
    section.add "X-Amz-Target", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Signature")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Signature", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Content-Sha256", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Date")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Date", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Credential")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Credential", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613609: Call_PollForThirdPartyJobs_613597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_613609.validator(path, query, header, formData, body)
  let scheme = call_613609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613609.url(scheme.get, call_613609.host, call_613609.base,
                         call_613609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613609, url, valid)

proc call*(call_613610: Call_PollForThirdPartyJobs_613597; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_613611 = newJObject()
  if body != nil:
    body_613611 = body
  result = call_613610.call(nil, nil, nil, nil, body_613611)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_613597(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_613598, base: "/",
    url: url_PollForThirdPartyJobs_613599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_613612 = ref object of OpenApiRestCall_612658
proc url_PutActionRevision_613614(protocol: Scheme; host: string; base: string;
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

proc validate_PutActionRevision_613613(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613615 = header.getOrDefault("X-Amz-Target")
  valid_613615 = validateParameter(valid_613615, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_613615 != nil:
    section.add "X-Amz-Target", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_PutActionRevision_613612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_PutActionRevision_613612; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_613626 = newJObject()
  if body != nil:
    body_613626 = body
  result = call_613625.call(nil, nil, nil, nil, body_613626)

var putActionRevision* = Call_PutActionRevision_613612(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_613613, base: "/",
    url: url_PutActionRevision_613614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_613627 = ref object of OpenApiRestCall_612658
proc url_PutApprovalResult_613629(protocol: Scheme; host: string; base: string;
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

proc validate_PutApprovalResult_613628(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613630 = header.getOrDefault("X-Amz-Target")
  valid_613630 = validateParameter(valid_613630, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_613630 != nil:
    section.add "X-Amz-Target", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Signature")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Signature", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Content-Sha256", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Date")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Date", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Credential")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Credential", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Security-Token")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Security-Token", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Algorithm")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Algorithm", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-SignedHeaders", valid_613637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613639: Call_PutApprovalResult_613627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_613639.validator(path, query, header, formData, body)
  let scheme = call_613639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613639.url(scheme.get, call_613639.host, call_613639.base,
                         call_613639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613639, url, valid)

proc call*(call_613640: Call_PutApprovalResult_613627; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_613641 = newJObject()
  if body != nil:
    body_613641 = body
  result = call_613640.call(nil, nil, nil, nil, body_613641)

var putApprovalResult* = Call_PutApprovalResult_613627(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_613628, base: "/",
    url: url_PutApprovalResult_613629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_613642 = ref object of OpenApiRestCall_612658
proc url_PutJobFailureResult_613644(protocol: Scheme; host: string; base: string;
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

proc validate_PutJobFailureResult_613643(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
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
  var valid_613645 = header.getOrDefault("X-Amz-Target")
  valid_613645 = validateParameter(valid_613645, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_613645 != nil:
    section.add "X-Amz-Target", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Signature")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Signature", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Content-Sha256", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Date")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Date", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Credential")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Credential", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Security-Token")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Security-Token", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Algorithm")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Algorithm", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-SignedHeaders", valid_613652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613654: Call_PutJobFailureResult_613642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_613654.validator(path, query, header, formData, body)
  let scheme = call_613654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613654.url(scheme.get, call_613654.host, call_613654.base,
                         call_613654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613654, url, valid)

proc call*(call_613655: Call_PutJobFailureResult_613642; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_613656 = newJObject()
  if body != nil:
    body_613656 = body
  result = call_613655.call(nil, nil, nil, nil, body_613656)

var putJobFailureResult* = Call_PutJobFailureResult_613642(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_613643, base: "/",
    url: url_PutJobFailureResult_613644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_613657 = ref object of OpenApiRestCall_612658
proc url_PutJobSuccessResult_613659(protocol: Scheme; host: string; base: string;
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

proc validate_PutJobSuccessResult_613658(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
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
  var valid_613660 = header.getOrDefault("X-Amz-Target")
  valid_613660 = validateParameter(valid_613660, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_613660 != nil:
    section.add "X-Amz-Target", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Signature")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Signature", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Content-Sha256", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Date")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Date", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Credential")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Credential", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Security-Token")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Security-Token", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Algorithm")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Algorithm", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-SignedHeaders", valid_613667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613669: Call_PutJobSuccessResult_613657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_613669.validator(path, query, header, formData, body)
  let scheme = call_613669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613669.url(scheme.get, call_613669.host, call_613669.base,
                         call_613669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613669, url, valid)

proc call*(call_613670: Call_PutJobSuccessResult_613657; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_613671 = newJObject()
  if body != nil:
    body_613671 = body
  result = call_613670.call(nil, nil, nil, nil, body_613671)

var putJobSuccessResult* = Call_PutJobSuccessResult_613657(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_613658, base: "/",
    url: url_PutJobSuccessResult_613659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_613672 = ref object of OpenApiRestCall_612658
proc url_PutThirdPartyJobFailureResult_613674(protocol: Scheme; host: string;
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

proc validate_PutThirdPartyJobFailureResult_613673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
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
  var valid_613675 = header.getOrDefault("X-Amz-Target")
  valid_613675 = validateParameter(valid_613675, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_613675 != nil:
    section.add "X-Amz-Target", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Signature")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Signature", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Content-Sha256", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Date")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Date", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Credential")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Credential", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Security-Token")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Security-Token", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Algorithm")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Algorithm", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-SignedHeaders", valid_613682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613684: Call_PutThirdPartyJobFailureResult_613672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_613684.validator(path, query, header, formData, body)
  let scheme = call_613684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613684.url(scheme.get, call_613684.host, call_613684.base,
                         call_613684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613684, url, valid)

proc call*(call_613685: Call_PutThirdPartyJobFailureResult_613672; body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_613686 = newJObject()
  if body != nil:
    body_613686 = body
  result = call_613685.call(nil, nil, nil, nil, body_613686)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_613672(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_613673, base: "/",
    url: url_PutThirdPartyJobFailureResult_613674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_613687 = ref object of OpenApiRestCall_612658
proc url_PutThirdPartyJobSuccessResult_613689(protocol: Scheme; host: string;
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

proc validate_PutThirdPartyJobSuccessResult_613688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
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
  var valid_613690 = header.getOrDefault("X-Amz-Target")
  valid_613690 = validateParameter(valid_613690, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_613690 != nil:
    section.add "X-Amz-Target", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Signature")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Signature", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Content-Sha256", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Date")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Date", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Credential")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Credential", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Security-Token")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Security-Token", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Algorithm")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Algorithm", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-SignedHeaders", valid_613697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613699: Call_PutThirdPartyJobSuccessResult_613687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_613699.validator(path, query, header, formData, body)
  let scheme = call_613699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613699.url(scheme.get, call_613699.host, call_613699.base,
                         call_613699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613699, url, valid)

proc call*(call_613700: Call_PutThirdPartyJobSuccessResult_613687; body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_613701 = newJObject()
  if body != nil:
    body_613701 = body
  result = call_613700.call(nil, nil, nil, nil, body_613701)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_613687(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_613688, base: "/",
    url: url_PutThirdPartyJobSuccessResult_613689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_613702 = ref object of OpenApiRestCall_612658
proc url_PutWebhook_613704(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutWebhook_613703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613705 = header.getOrDefault("X-Amz-Target")
  valid_613705 = validateParameter(valid_613705, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_613705 != nil:
    section.add "X-Amz-Target", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Signature")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Signature", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Content-Sha256", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Date")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Date", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Credential")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Credential", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613714: Call_PutWebhook_613702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_613714.validator(path, query, header, formData, body)
  let scheme = call_613714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613714.url(scheme.get, call_613714.host, call_613714.base,
                         call_613714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613714, url, valid)

proc call*(call_613715: Call_PutWebhook_613702; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_613716 = newJObject()
  if body != nil:
    body_613716 = body
  result = call_613715.call(nil, nil, nil, nil, body_613716)

var putWebhook* = Call_PutWebhook_613702(name: "putWebhook",
                                      meth: HttpMethod.HttpPost,
                                      host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                      validator: validate_PutWebhook_613703,
                                      base: "/", url: url_PutWebhook_613704,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_613717 = ref object of OpenApiRestCall_612658
proc url_RegisterWebhookWithThirdParty_613719(protocol: Scheme; host: string;
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

proc validate_RegisterWebhookWithThirdParty_613718(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613720 = header.getOrDefault("X-Amz-Target")
  valid_613720 = validateParameter(valid_613720, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_613720 != nil:
    section.add "X-Amz-Target", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Signature")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Signature", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Content-Sha256", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Date")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Date", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Credential")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Credential", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Security-Token")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Security-Token", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Algorithm")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Algorithm", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-SignedHeaders", valid_613727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613729: Call_RegisterWebhookWithThirdParty_613717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_613729.validator(path, query, header, formData, body)
  let scheme = call_613729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613729.url(scheme.get, call_613729.host, call_613729.base,
                         call_613729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613729, url, valid)

proc call*(call_613730: Call_RegisterWebhookWithThirdParty_613717; body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_613731 = newJObject()
  if body != nil:
    body_613731 = body
  result = call_613730.call(nil, nil, nil, nil, body_613731)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_613717(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_613718, base: "/",
    url: url_RegisterWebhookWithThirdParty_613719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_613732 = ref object of OpenApiRestCall_612658
proc url_RetryStageExecution_613734(protocol: Scheme; host: string; base: string;
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

proc validate_RetryStageExecution_613733(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
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
  var valid_613735 = header.getOrDefault("X-Amz-Target")
  valid_613735 = validateParameter(valid_613735, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_613735 != nil:
    section.add "X-Amz-Target", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Signature")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Signature", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Content-Sha256", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Date")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Date", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Credential")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Credential", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Security-Token")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Security-Token", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Algorithm")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Algorithm", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-SignedHeaders", valid_613742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613744: Call_RetryStageExecution_613732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ## 
  let valid = call_613744.validator(path, query, header, formData, body)
  let scheme = call_613744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613744.url(scheme.get, call_613744.host, call_613744.base,
                         call_613744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613744, url, valid)

proc call*(call_613745: Call_RetryStageExecution_613732; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ##   body: JObject (required)
  var body_613746 = newJObject()
  if body != nil:
    body_613746 = body
  result = call_613745.call(nil, nil, nil, nil, body_613746)

var retryStageExecution* = Call_RetryStageExecution_613732(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_613733, base: "/",
    url: url_RetryStageExecution_613734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_613747 = ref object of OpenApiRestCall_612658
proc url_StartPipelineExecution_613749(protocol: Scheme; host: string; base: string;
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

proc validate_StartPipelineExecution_613748(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613750 = header.getOrDefault("X-Amz-Target")
  valid_613750 = validateParameter(valid_613750, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_613750 != nil:
    section.add "X-Amz-Target", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Signature")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Signature", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Content-Sha256", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Date")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Date", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Credential")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Credential", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Security-Token")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Security-Token", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Algorithm")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Algorithm", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-SignedHeaders", valid_613757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613759: Call_StartPipelineExecution_613747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_613759.validator(path, query, header, formData, body)
  let scheme = call_613759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613759.url(scheme.get, call_613759.host, call_613759.base,
                         call_613759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613759, url, valid)

proc call*(call_613760: Call_StartPipelineExecution_613747; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_613761 = newJObject()
  if body != nil:
    body_613761 = body
  result = call_613760.call(nil, nil, nil, nil, body_613761)

var startPipelineExecution* = Call_StartPipelineExecution_613747(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_613748, base: "/",
    url: url_StartPipelineExecution_613749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopPipelineExecution_613762 = ref object of OpenApiRestCall_612658
proc url_StopPipelineExecution_613764(protocol: Scheme; host: string; base: string;
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

proc validate_StopPipelineExecution_613763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
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
  var valid_613765 = header.getOrDefault("X-Amz-Target")
  valid_613765 = validateParameter(valid_613765, JString, required = true, default = newJString(
      "CodePipeline_20150709.StopPipelineExecution"))
  if valid_613765 != nil:
    section.add "X-Amz-Target", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Signature")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Signature", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Content-Sha256", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Date")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Date", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Credential")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Credential", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Security-Token")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Security-Token", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Algorithm")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Algorithm", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-SignedHeaders", valid_613772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613774: Call_StopPipelineExecution_613762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ## 
  let valid = call_613774.validator(path, query, header, formData, body)
  let scheme = call_613774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613774.url(scheme.get, call_613774.host, call_613774.base,
                         call_613774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613774, url, valid)

proc call*(call_613775: Call_StopPipelineExecution_613762; body: JsonNode): Recallable =
  ## stopPipelineExecution
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ##   body: JObject (required)
  var body_613776 = newJObject()
  if body != nil:
    body_613776 = body
  result = call_613775.call(nil, nil, nil, nil, body_613776)

var stopPipelineExecution* = Call_StopPipelineExecution_613762(
    name: "stopPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StopPipelineExecution",
    validator: validate_StopPipelineExecution_613763, base: "/",
    url: url_StopPipelineExecution_613764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613777 = ref object of OpenApiRestCall_612658
proc url_TagResource_613779(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613778(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613780 = header.getOrDefault("X-Amz-Target")
  valid_613780 = validateParameter(valid_613780, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_613780 != nil:
    section.add "X-Amz-Target", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Signature")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Signature", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Content-Sha256", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Date")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Date", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Credential")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Credential", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Security-Token")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Security-Token", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Algorithm")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Algorithm", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-SignedHeaders", valid_613787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613789: Call_TagResource_613777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_613789.validator(path, query, header, formData, body)
  let scheme = call_613789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613789.url(scheme.get, call_613789.host, call_613789.base,
                         call_613789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613789, url, valid)

proc call*(call_613790: Call_TagResource_613777; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_613791 = newJObject()
  if body != nil:
    body_613791 = body
  result = call_613790.call(nil, nil, nil, nil, body_613791)

var tagResource* = Call_TagResource_613777(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
                                        validator: validate_TagResource_613778,
                                        base: "/", url: url_TagResource_613779,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613792 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613794(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613793(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613795 = header.getOrDefault("X-Amz-Target")
  valid_613795 = validateParameter(valid_613795, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_613795 != nil:
    section.add "X-Amz-Target", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Signature")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Signature", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Content-Sha256", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Date")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Date", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Credential")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Credential", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Security-Token")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Security-Token", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Algorithm")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Algorithm", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-SignedHeaders", valid_613802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613804: Call_UntagResource_613792; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_613804.validator(path, query, header, formData, body)
  let scheme = call_613804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613804.url(scheme.get, call_613804.host, call_613804.base,
                         call_613804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613804, url, valid)

proc call*(call_613805: Call_UntagResource_613792; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_613806 = newJObject()
  if body != nil:
    body_613806 = body
  result = call_613805.call(nil, nil, nil, nil, body_613806)

var untagResource* = Call_UntagResource_613792(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_613793, base: "/", url: url_UntagResource_613794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_613807 = ref object of OpenApiRestCall_612658
proc url_UpdatePipeline_613809(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_613808(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
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
  var valid_613810 = header.getOrDefault("X-Amz-Target")
  valid_613810 = validateParameter(valid_613810, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_613810 != nil:
    section.add "X-Amz-Target", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Signature")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Signature", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Content-Sha256", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Date")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Date", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Credential")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Credential", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Security-Token")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Security-Token", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Algorithm")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Algorithm", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-SignedHeaders", valid_613817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613819: Call_UpdatePipeline_613807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_613819.validator(path, query, header, formData, body)
  let scheme = call_613819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613819.url(scheme.get, call_613819.host, call_613819.base,
                         call_613819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613819, url, valid)

proc call*(call_613820: Call_UpdatePipeline_613807; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_613821 = newJObject()
  if body != nil:
    body_613821 = body
  result = call_613820.call(nil, nil, nil, nil, body_613821)

var updatePipeline* = Call_UpdatePipeline_613807(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_613808, base: "/", url: url_UpdatePipeline_613809,
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
