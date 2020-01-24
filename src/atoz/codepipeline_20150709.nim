
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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  Call_AcknowledgeJob_606927 = ref object of OpenApiRestCall_606589
proc url_AcknowledgeJob_606929(protocol: Scheme; host: string; base: string;
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

proc validate_AcknowledgeJob_606928(path: JsonNode; query: JsonNode;
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
  var valid_607054 = header.getOrDefault("X-Amz-Target")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_607054 != nil:
    section.add "X-Amz-Target", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_AcknowledgeJob_606927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607156: Call_AcknowledgeJob_606927; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_607157 = newJObject()
  if body != nil:
    body_607157 = body
  result = call_607156.call(nil, nil, nil, nil, body_607157)

var acknowledgeJob* = Call_AcknowledgeJob_606927(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_606928, base: "/", url: url_AcknowledgeJob_606929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_607196 = ref object of OpenApiRestCall_606589
proc url_AcknowledgeThirdPartyJob_607198(protocol: Scheme; host: string;
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

proc validate_AcknowledgeThirdPartyJob_607197(path: JsonNode; query: JsonNode;
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
  var valid_607199 = header.getOrDefault("X-Amz-Target")
  valid_607199 = validateParameter(valid_607199, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_607199 != nil:
    section.add "X-Amz-Target", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Signature")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Signature", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Content-Sha256", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Date")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Date", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Credential")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Credential", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Security-Token")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Security-Token", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Algorithm")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Algorithm", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-SignedHeaders", valid_607206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607208: Call_AcknowledgeThirdPartyJob_607196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ## 
  let valid = call_607208.validator(path, query, header, formData, body)
  let scheme = call_607208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607208.url(scheme.get, call_607208.host, call_607208.base,
                         call_607208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607208, url, valid)

proc call*(call_607209: Call_AcknowledgeThirdPartyJob_607196; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ##   body: JObject (required)
  var body_607210 = newJObject()
  if body != nil:
    body_607210 = body
  result = call_607209.call(nil, nil, nil, nil, body_607210)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_607196(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_607197, base: "/",
    url: url_AcknowledgeThirdPartyJob_607198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_607211 = ref object of OpenApiRestCall_606589
proc url_CreateCustomActionType_607213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomActionType_607212(path: JsonNode; query: JsonNode;
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
  var valid_607214 = header.getOrDefault("X-Amz-Target")
  valid_607214 = validateParameter(valid_607214, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_607214 != nil:
    section.add "X-Amz-Target", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Signature")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Signature", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Content-Sha256", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Date")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Date", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Credential")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Credential", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Security-Token")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Security-Token", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Algorithm")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Algorithm", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-SignedHeaders", valid_607221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607223: Call_CreateCustomActionType_607211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_607223.validator(path, query, header, formData, body)
  let scheme = call_607223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607223.url(scheme.get, call_607223.host, call_607223.base,
                         call_607223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607223, url, valid)

proc call*(call_607224: Call_CreateCustomActionType_607211; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_607225 = newJObject()
  if body != nil:
    body_607225 = body
  result = call_607224.call(nil, nil, nil, nil, body_607225)

var createCustomActionType* = Call_CreateCustomActionType_607211(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_607212, base: "/",
    url: url_CreateCustomActionType_607213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_607226 = ref object of OpenApiRestCall_606589
proc url_CreatePipeline_607228(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_607227(path: JsonNode; query: JsonNode;
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
  var valid_607229 = header.getOrDefault("X-Amz-Target")
  valid_607229 = validateParameter(valid_607229, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_607229 != nil:
    section.add "X-Amz-Target", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Signature")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Signature", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Content-Sha256", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Date")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Date", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Credential")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Credential", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Security-Token")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Security-Token", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Algorithm")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Algorithm", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-SignedHeaders", valid_607236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607238: Call_CreatePipeline_607226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_607238.validator(path, query, header, formData, body)
  let scheme = call_607238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607238.url(scheme.get, call_607238.host, call_607238.base,
                         call_607238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607238, url, valid)

proc call*(call_607239: Call_CreatePipeline_607226; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_607240 = newJObject()
  if body != nil:
    body_607240 = body
  result = call_607239.call(nil, nil, nil, nil, body_607240)

var createPipeline* = Call_CreatePipeline_607226(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_607227, base: "/", url: url_CreatePipeline_607228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_607241 = ref object of OpenApiRestCall_606589
proc url_DeleteCustomActionType_607243(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomActionType_607242(path: JsonNode; query: JsonNode;
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
  var valid_607244 = header.getOrDefault("X-Amz-Target")
  valid_607244 = validateParameter(valid_607244, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_607244 != nil:
    section.add "X-Amz-Target", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Signature")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Signature", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Content-Sha256", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Date")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Date", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Credential")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Credential", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Security-Token")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Security-Token", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Algorithm")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Algorithm", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-SignedHeaders", valid_607251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_DeleteCustomActionType_607241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_DeleteCustomActionType_607241; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_607255 = newJObject()
  if body != nil:
    body_607255 = body
  result = call_607254.call(nil, nil, nil, nil, body_607255)

var deleteCustomActionType* = Call_DeleteCustomActionType_607241(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_607242, base: "/",
    url: url_DeleteCustomActionType_607243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_607256 = ref object of OpenApiRestCall_606589
proc url_DeletePipeline_607258(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_607257(path: JsonNode; query: JsonNode;
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
  var valid_607259 = header.getOrDefault("X-Amz-Target")
  valid_607259 = validateParameter(valid_607259, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_607259 != nil:
    section.add "X-Amz-Target", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607268: Call_DeletePipeline_607256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_607268.validator(path, query, header, formData, body)
  let scheme = call_607268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607268.url(scheme.get, call_607268.host, call_607268.base,
                         call_607268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607268, url, valid)

proc call*(call_607269: Call_DeletePipeline_607256; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_607270 = newJObject()
  if body != nil:
    body_607270 = body
  result = call_607269.call(nil, nil, nil, nil, body_607270)

var deletePipeline* = Call_DeletePipeline_607256(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_607257, base: "/", url: url_DeletePipeline_607258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_607271 = ref object of OpenApiRestCall_606589
proc url_DeleteWebhook_607273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_607272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607274 = header.getOrDefault("X-Amz-Target")
  valid_607274 = validateParameter(valid_607274, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_607274 != nil:
    section.add "X-Amz-Target", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_DeleteWebhook_607271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_DeleteWebhook_607271; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_607285 = newJObject()
  if body != nil:
    body_607285 = body
  result = call_607284.call(nil, nil, nil, nil, body_607285)

var deleteWebhook* = Call_DeleteWebhook_607271(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_607272, base: "/", url: url_DeleteWebhook_607273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_607286 = ref object of OpenApiRestCall_606589
proc url_DeregisterWebhookWithThirdParty_607288(protocol: Scheme; host: string;
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

proc validate_DeregisterWebhookWithThirdParty_607287(path: JsonNode;
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
  var valid_607289 = header.getOrDefault("X-Amz-Target")
  valid_607289 = validateParameter(valid_607289, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_607289 != nil:
    section.add "X-Amz-Target", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Signature")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Signature", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Content-Sha256", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Date")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Date", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Credential")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Credential", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Security-Token")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Security-Token", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Algorithm")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Algorithm", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-SignedHeaders", valid_607296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607298: Call_DeregisterWebhookWithThirdParty_607286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ## 
  let valid = call_607298.validator(path, query, header, formData, body)
  let scheme = call_607298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607298.url(scheme.get, call_607298.host, call_607298.base,
                         call_607298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607298, url, valid)

proc call*(call_607299: Call_DeregisterWebhookWithThirdParty_607286; body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_607300 = newJObject()
  if body != nil:
    body_607300 = body
  result = call_607299.call(nil, nil, nil, nil, body_607300)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_607286(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_607287, base: "/",
    url: url_DeregisterWebhookWithThirdParty_607288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_607301 = ref object of OpenApiRestCall_606589
proc url_DisableStageTransition_607303(protocol: Scheme; host: string; base: string;
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

proc validate_DisableStageTransition_607302(path: JsonNode; query: JsonNode;
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
  var valid_607304 = header.getOrDefault("X-Amz-Target")
  valid_607304 = validateParameter(valid_607304, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_607304 != nil:
    section.add "X-Amz-Target", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607313: Call_DisableStageTransition_607301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_607313.validator(path, query, header, formData, body)
  let scheme = call_607313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607313.url(scheme.get, call_607313.host, call_607313.base,
                         call_607313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607313, url, valid)

proc call*(call_607314: Call_DisableStageTransition_607301; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_607315 = newJObject()
  if body != nil:
    body_607315 = body
  result = call_607314.call(nil, nil, nil, nil, body_607315)

var disableStageTransition* = Call_DisableStageTransition_607301(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_607302, base: "/",
    url: url_DisableStageTransition_607303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_607316 = ref object of OpenApiRestCall_606589
proc url_EnableStageTransition_607318(protocol: Scheme; host: string; base: string;
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

proc validate_EnableStageTransition_607317(path: JsonNode; query: JsonNode;
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
  var valid_607319 = header.getOrDefault("X-Amz-Target")
  valid_607319 = validateParameter(valid_607319, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_607319 != nil:
    section.add "X-Amz-Target", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Signature")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Signature", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Content-Sha256", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Date")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Date", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Credential")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Credential", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Security-Token")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Security-Token", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Algorithm")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Algorithm", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-SignedHeaders", valid_607326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_EnableStageTransition_607316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_EnableStageTransition_607316; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_607330 = newJObject()
  if body != nil:
    body_607330 = body
  result = call_607329.call(nil, nil, nil, nil, body_607330)

var enableStageTransition* = Call_EnableStageTransition_607316(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_607317, base: "/",
    url: url_EnableStageTransition_607318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_607331 = ref object of OpenApiRestCall_606589
proc url_GetJobDetails_607333(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobDetails_607332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607334 = header.getOrDefault("X-Amz-Target")
  valid_607334 = validateParameter(valid_607334, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_607334 != nil:
    section.add "X-Amz-Target", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Signature")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Signature", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Content-Sha256", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Date")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Date", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Credential")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Credential", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Security-Token")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Security-Token", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Algorithm")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Algorithm", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-SignedHeaders", valid_607341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607343: Call_GetJobDetails_607331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_GetJobDetails_607331; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_607345 = newJObject()
  if body != nil:
    body_607345 = body
  result = call_607344.call(nil, nil, nil, nil, body_607345)

var getJobDetails* = Call_GetJobDetails_607331(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_607332, base: "/", url: url_GetJobDetails_607333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_607346 = ref object of OpenApiRestCall_606589
proc url_GetPipeline_607348(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipeline_607347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607349 = header.getOrDefault("X-Amz-Target")
  valid_607349 = validateParameter(valid_607349, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_607349 != nil:
    section.add "X-Amz-Target", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Signature")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Signature", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Content-Sha256", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Date")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Date", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Credential")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Credential", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Security-Token")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Security-Token", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Algorithm")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Algorithm", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-SignedHeaders", valid_607356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_GetPipeline_607346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_GetPipeline_607346; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_607360 = newJObject()
  if body != nil:
    body_607360 = body
  result = call_607359.call(nil, nil, nil, nil, body_607360)

var getPipeline* = Call_GetPipeline_607346(name: "getPipeline",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
                                        validator: validate_GetPipeline_607347,
                                        base: "/", url: url_GetPipeline_607348,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_607361 = ref object of OpenApiRestCall_606589
proc url_GetPipelineExecution_607363(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipelineExecution_607362(path: JsonNode; query: JsonNode;
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
  var valid_607364 = header.getOrDefault("X-Amz-Target")
  valid_607364 = validateParameter(valid_607364, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_607364 != nil:
    section.add "X-Amz-Target", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Signature")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Signature", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Content-Sha256", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Date")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Date", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Credential")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Credential", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Security-Token")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Security-Token", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Algorithm")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Algorithm", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-SignedHeaders", valid_607371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607373: Call_GetPipelineExecution_607361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_607373.validator(path, query, header, formData, body)
  let scheme = call_607373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607373.url(scheme.get, call_607373.host, call_607373.base,
                         call_607373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607373, url, valid)

proc call*(call_607374: Call_GetPipelineExecution_607361; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_607375 = newJObject()
  if body != nil:
    body_607375 = body
  result = call_607374.call(nil, nil, nil, nil, body_607375)

var getPipelineExecution* = Call_GetPipelineExecution_607361(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_607362, base: "/",
    url: url_GetPipelineExecution_607363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_607376 = ref object of OpenApiRestCall_606589
proc url_GetPipelineState_607378(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipelineState_607377(path: JsonNode; query: JsonNode;
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
  var valid_607379 = header.getOrDefault("X-Amz-Target")
  valid_607379 = validateParameter(valid_607379, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_607379 != nil:
    section.add "X-Amz-Target", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607388: Call_GetPipelineState_607376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_607388.validator(path, query, header, formData, body)
  let scheme = call_607388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607388.url(scheme.get, call_607388.host, call_607388.base,
                         call_607388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607388, url, valid)

proc call*(call_607389: Call_GetPipelineState_607376; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_607390 = newJObject()
  if body != nil:
    body_607390 = body
  result = call_607389.call(nil, nil, nil, nil, body_607390)

var getPipelineState* = Call_GetPipelineState_607376(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_607377, base: "/",
    url: url_GetPipelineState_607378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_607391 = ref object of OpenApiRestCall_606589
proc url_GetThirdPartyJobDetails_607393(protocol: Scheme; host: string; base: string;
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

proc validate_GetThirdPartyJobDetails_607392(path: JsonNode; query: JsonNode;
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
  var valid_607394 = header.getOrDefault("X-Amz-Target")
  valid_607394 = validateParameter(valid_607394, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_607394 != nil:
    section.add "X-Amz-Target", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-Signature")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Signature", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Content-Sha256", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Date")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Date", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Credential")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Credential", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Security-Token")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Security-Token", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Algorithm")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Algorithm", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-SignedHeaders", valid_607401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607403: Call_GetThirdPartyJobDetails_607391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_607403.validator(path, query, header, formData, body)
  let scheme = call_607403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607403.url(scheme.get, call_607403.host, call_607403.base,
                         call_607403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607403, url, valid)

proc call*(call_607404: Call_GetThirdPartyJobDetails_607391; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_607405 = newJObject()
  if body != nil:
    body_607405 = body
  result = call_607404.call(nil, nil, nil, nil, body_607405)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_607391(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_607392, base: "/",
    url: url_GetThirdPartyJobDetails_607393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_607406 = ref object of OpenApiRestCall_606589
proc url_ListActionExecutions_607408(protocol: Scheme; host: string; base: string;
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

proc validate_ListActionExecutions_607407(path: JsonNode; query: JsonNode;
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
  var valid_607409 = query.getOrDefault("nextToken")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "nextToken", valid_607409
  var valid_607410 = query.getOrDefault("maxResults")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "maxResults", valid_607410
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
  var valid_607411 = header.getOrDefault("X-Amz-Target")
  valid_607411 = validateParameter(valid_607411, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionExecutions"))
  if valid_607411 != nil:
    section.add "X-Amz-Target", valid_607411
  var valid_607412 = header.getOrDefault("X-Amz-Signature")
  valid_607412 = validateParameter(valid_607412, JString, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "X-Amz-Signature", valid_607412
  var valid_607413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "X-Amz-Content-Sha256", valid_607413
  var valid_607414 = header.getOrDefault("X-Amz-Date")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Date", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-Credential")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-Credential", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-Security-Token")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Security-Token", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Algorithm")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Algorithm", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-SignedHeaders", valid_607418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607420: Call_ListActionExecutions_607406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_607420.validator(path, query, header, formData, body)
  let scheme = call_607420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607420.url(scheme.get, call_607420.host, call_607420.base,
                         call_607420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607420, url, valid)

proc call*(call_607421: Call_ListActionExecutions_607406; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_607422 = newJObject()
  var body_607423 = newJObject()
  add(query_607422, "nextToken", newJString(nextToken))
  if body != nil:
    body_607423 = body
  add(query_607422, "maxResults", newJString(maxResults))
  result = call_607421.call(nil, query_607422, nil, nil, body_607423)

var listActionExecutions* = Call_ListActionExecutions_607406(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_607407, base: "/",
    url: url_ListActionExecutions_607408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_607425 = ref object of OpenApiRestCall_606589
proc url_ListActionTypes_607427(protocol: Scheme; host: string; base: string;
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

proc validate_ListActionTypes_607426(path: JsonNode; query: JsonNode;
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
  var valid_607428 = query.getOrDefault("nextToken")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "nextToken", valid_607428
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
  var valid_607429 = header.getOrDefault("X-Amz-Target")
  valid_607429 = validateParameter(valid_607429, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_607429 != nil:
    section.add "X-Amz-Target", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Signature")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Signature", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-Content-Sha256", valid_607431
  var valid_607432 = header.getOrDefault("X-Amz-Date")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "X-Amz-Date", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Credential")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Credential", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Security-Token")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Security-Token", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Algorithm")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Algorithm", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-SignedHeaders", valid_607436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607438: Call_ListActionTypes_607425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_607438.validator(path, query, header, formData, body)
  let scheme = call_607438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607438.url(scheme.get, call_607438.host, call_607438.base,
                         call_607438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607438, url, valid)

proc call*(call_607439: Call_ListActionTypes_607425; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607440 = newJObject()
  var body_607441 = newJObject()
  add(query_607440, "nextToken", newJString(nextToken))
  if body != nil:
    body_607441 = body
  result = call_607439.call(nil, query_607440, nil, nil, body_607441)

var listActionTypes* = Call_ListActionTypes_607425(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_607426, base: "/", url: url_ListActionTypes_607427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_607442 = ref object of OpenApiRestCall_606589
proc url_ListPipelineExecutions_607444(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelineExecutions_607443(path: JsonNode; query: JsonNode;
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
  var valid_607445 = query.getOrDefault("nextToken")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "nextToken", valid_607445
  var valid_607446 = query.getOrDefault("maxResults")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "maxResults", valid_607446
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
  var valid_607447 = header.getOrDefault("X-Amz-Target")
  valid_607447 = validateParameter(valid_607447, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_607447 != nil:
    section.add "X-Amz-Target", valid_607447
  var valid_607448 = header.getOrDefault("X-Amz-Signature")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "X-Amz-Signature", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-Content-Sha256", valid_607449
  var valid_607450 = header.getOrDefault("X-Amz-Date")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "X-Amz-Date", valid_607450
  var valid_607451 = header.getOrDefault("X-Amz-Credential")
  valid_607451 = validateParameter(valid_607451, JString, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "X-Amz-Credential", valid_607451
  var valid_607452 = header.getOrDefault("X-Amz-Security-Token")
  valid_607452 = validateParameter(valid_607452, JString, required = false,
                                 default = nil)
  if valid_607452 != nil:
    section.add "X-Amz-Security-Token", valid_607452
  var valid_607453 = header.getOrDefault("X-Amz-Algorithm")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-Algorithm", valid_607453
  var valid_607454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-SignedHeaders", valid_607454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607456: Call_ListPipelineExecutions_607442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_607456.validator(path, query, header, formData, body)
  let scheme = call_607456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607456.url(scheme.get, call_607456.host, call_607456.base,
                         call_607456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607456, url, valid)

proc call*(call_607457: Call_ListPipelineExecutions_607442; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_607458 = newJObject()
  var body_607459 = newJObject()
  add(query_607458, "nextToken", newJString(nextToken))
  if body != nil:
    body_607459 = body
  add(query_607458, "maxResults", newJString(maxResults))
  result = call_607457.call(nil, query_607458, nil, nil, body_607459)

var listPipelineExecutions* = Call_ListPipelineExecutions_607442(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_607443, base: "/",
    url: url_ListPipelineExecutions_607444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_607460 = ref object of OpenApiRestCall_606589
proc url_ListPipelines_607462(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_607461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607463 = query.getOrDefault("nextToken")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "nextToken", valid_607463
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
  var valid_607464 = header.getOrDefault("X-Amz-Target")
  valid_607464 = validateParameter(valid_607464, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_607464 != nil:
    section.add "X-Amz-Target", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Signature")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Signature", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Content-Sha256", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-Date")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Date", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Credential")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Credential", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-Security-Token")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-Security-Token", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Algorithm")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Algorithm", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-SignedHeaders", valid_607471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607473: Call_ListPipelines_607460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_607473.validator(path, query, header, formData, body)
  let scheme = call_607473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607473.url(scheme.get, call_607473.host, call_607473.base,
                         call_607473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607473, url, valid)

proc call*(call_607474: Call_ListPipelines_607460; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607475 = newJObject()
  var body_607476 = newJObject()
  add(query_607475, "nextToken", newJString(nextToken))
  if body != nil:
    body_607476 = body
  result = call_607474.call(nil, query_607475, nil, nil, body_607476)

var listPipelines* = Call_ListPipelines_607460(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_607461, base: "/", url: url_ListPipelines_607462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607477 = ref object of OpenApiRestCall_606589
proc url_ListTagsForResource_607479(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_607478(path: JsonNode; query: JsonNode;
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
  var valid_607480 = query.getOrDefault("nextToken")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "nextToken", valid_607480
  var valid_607481 = query.getOrDefault("maxResults")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "maxResults", valid_607481
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
  var valid_607482 = header.getOrDefault("X-Amz-Target")
  valid_607482 = validateParameter(valid_607482, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_607482 != nil:
    section.add "X-Amz-Target", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Signature")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Signature", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-Content-Sha256", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Date")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Date", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Credential")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Credential", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Security-Token")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Security-Token", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Algorithm")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Algorithm", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-SignedHeaders", valid_607489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607491: Call_ListTagsForResource_607477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_607491.validator(path, query, header, formData, body)
  let scheme = call_607491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607491.url(scheme.get, call_607491.host, call_607491.base,
                         call_607491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607491, url, valid)

proc call*(call_607492: Call_ListTagsForResource_607477; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_607493 = newJObject()
  var body_607494 = newJObject()
  add(query_607493, "nextToken", newJString(nextToken))
  if body != nil:
    body_607494 = body
  add(query_607493, "maxResults", newJString(maxResults))
  result = call_607492.call(nil, query_607493, nil, nil, body_607494)

var listTagsForResource* = Call_ListTagsForResource_607477(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_607478, base: "/",
    url: url_ListTagsForResource_607479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_607495 = ref object of OpenApiRestCall_606589
proc url_ListWebhooks_607497(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_607496(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607498 = query.getOrDefault("MaxResults")
  valid_607498 = validateParameter(valid_607498, JString, required = false,
                                 default = nil)
  if valid_607498 != nil:
    section.add "MaxResults", valid_607498
  var valid_607499 = query.getOrDefault("NextToken")
  valid_607499 = validateParameter(valid_607499, JString, required = false,
                                 default = nil)
  if valid_607499 != nil:
    section.add "NextToken", valid_607499
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
  var valid_607500 = header.getOrDefault("X-Amz-Target")
  valid_607500 = validateParameter(valid_607500, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_607500 != nil:
    section.add "X-Amz-Target", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Signature")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Signature", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Content-Sha256", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Date")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Date", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Credential")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Credential", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Security-Token")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Security-Token", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-Algorithm")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-Algorithm", valid_607506
  var valid_607507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "X-Amz-SignedHeaders", valid_607507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607509: Call_ListWebhooks_607495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  let valid = call_607509.validator(path, query, header, formData, body)
  let scheme = call_607509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607509.url(scheme.get, call_607509.host, call_607509.base,
                         call_607509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607509, url, valid)

proc call*(call_607510: Call_ListWebhooks_607495; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607511 = newJObject()
  var body_607512 = newJObject()
  add(query_607511, "MaxResults", newJString(MaxResults))
  add(query_607511, "NextToken", newJString(NextToken))
  if body != nil:
    body_607512 = body
  result = call_607510.call(nil, query_607511, nil, nil, body_607512)

var listWebhooks* = Call_ListWebhooks_607495(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_607496, base: "/", url: url_ListWebhooks_607497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_607513 = ref object of OpenApiRestCall_606589
proc url_PollForJobs_607515(protocol: Scheme; host: string; base: string;
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

proc validate_PollForJobs_607514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607516 = header.getOrDefault("X-Amz-Target")
  valid_607516 = validateParameter(valid_607516, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_607516 != nil:
    section.add "X-Amz-Target", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Signature")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Signature", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Content-Sha256", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Date")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Date", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Credential")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Credential", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-Security-Token")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-Security-Token", valid_607521
  var valid_607522 = header.getOrDefault("X-Amz-Algorithm")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-Algorithm", valid_607522
  var valid_607523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-SignedHeaders", valid_607523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607525: Call_PollForJobs_607513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_607525.validator(path, query, header, formData, body)
  let scheme = call_607525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607525.url(scheme.get, call_607525.host, call_607525.base,
                         call_607525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607525, url, valid)

proc call*(call_607526: Call_PollForJobs_607513; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_607527 = newJObject()
  if body != nil:
    body_607527 = body
  result = call_607526.call(nil, nil, nil, nil, body_607527)

var pollForJobs* = Call_PollForJobs_607513(name: "pollForJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
                                        validator: validate_PollForJobs_607514,
                                        base: "/", url: url_PollForJobs_607515,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_607528 = ref object of OpenApiRestCall_606589
proc url_PollForThirdPartyJobs_607530(protocol: Scheme; host: string; base: string;
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

proc validate_PollForThirdPartyJobs_607529(path: JsonNode; query: JsonNode;
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
  var valid_607531 = header.getOrDefault("X-Amz-Target")
  valid_607531 = validateParameter(valid_607531, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_607531 != nil:
    section.add "X-Amz-Target", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Signature")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Signature", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Content-Sha256", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Date")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Date", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Credential")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Credential", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-Security-Token")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Security-Token", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Algorithm")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Algorithm", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-SignedHeaders", valid_607538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607540: Call_PollForThirdPartyJobs_607528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_607540.validator(path, query, header, formData, body)
  let scheme = call_607540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607540.url(scheme.get, call_607540.host, call_607540.base,
                         call_607540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607540, url, valid)

proc call*(call_607541: Call_PollForThirdPartyJobs_607528; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the S3 bucket used to store artifacts for the pipeline, if the action requires access to that S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_607542 = newJObject()
  if body != nil:
    body_607542 = body
  result = call_607541.call(nil, nil, nil, nil, body_607542)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_607528(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_607529, base: "/",
    url: url_PollForThirdPartyJobs_607530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_607543 = ref object of OpenApiRestCall_606589
proc url_PutActionRevision_607545(protocol: Scheme; host: string; base: string;
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

proc validate_PutActionRevision_607544(path: JsonNode; query: JsonNode;
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
  var valid_607546 = header.getOrDefault("X-Amz-Target")
  valid_607546 = validateParameter(valid_607546, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_607546 != nil:
    section.add "X-Amz-Target", valid_607546
  var valid_607547 = header.getOrDefault("X-Amz-Signature")
  valid_607547 = validateParameter(valid_607547, JString, required = false,
                                 default = nil)
  if valid_607547 != nil:
    section.add "X-Amz-Signature", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Content-Sha256", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Date")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Date", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Credential")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Credential", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Security-Token")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Security-Token", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Algorithm")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Algorithm", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-SignedHeaders", valid_607553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607555: Call_PutActionRevision_607543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_607555.validator(path, query, header, formData, body)
  let scheme = call_607555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607555.url(scheme.get, call_607555.host, call_607555.base,
                         call_607555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607555, url, valid)

proc call*(call_607556: Call_PutActionRevision_607543; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_607557 = newJObject()
  if body != nil:
    body_607557 = body
  result = call_607556.call(nil, nil, nil, nil, body_607557)

var putActionRevision* = Call_PutActionRevision_607543(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_607544, base: "/",
    url: url_PutActionRevision_607545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_607558 = ref object of OpenApiRestCall_606589
proc url_PutApprovalResult_607560(protocol: Scheme; host: string; base: string;
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

proc validate_PutApprovalResult_607559(path: JsonNode; query: JsonNode;
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
  var valid_607561 = header.getOrDefault("X-Amz-Target")
  valid_607561 = validateParameter(valid_607561, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_607561 != nil:
    section.add "X-Amz-Target", valid_607561
  var valid_607562 = header.getOrDefault("X-Amz-Signature")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "X-Amz-Signature", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Content-Sha256", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Date")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Date", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Credential")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Credential", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Security-Token")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Security-Token", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Algorithm")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Algorithm", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-SignedHeaders", valid_607568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607570: Call_PutApprovalResult_607558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_607570.validator(path, query, header, formData, body)
  let scheme = call_607570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607570.url(scheme.get, call_607570.host, call_607570.base,
                         call_607570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607570, url, valid)

proc call*(call_607571: Call_PutApprovalResult_607558; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_607572 = newJObject()
  if body != nil:
    body_607572 = body
  result = call_607571.call(nil, nil, nil, nil, body_607572)

var putApprovalResult* = Call_PutApprovalResult_607558(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_607559, base: "/",
    url: url_PutApprovalResult_607560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_607573 = ref object of OpenApiRestCall_606589
proc url_PutJobFailureResult_607575(protocol: Scheme; host: string; base: string;
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

proc validate_PutJobFailureResult_607574(path: JsonNode; query: JsonNode;
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
  var valid_607576 = header.getOrDefault("X-Amz-Target")
  valid_607576 = validateParameter(valid_607576, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_607576 != nil:
    section.add "X-Amz-Target", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Signature")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Signature", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Content-Sha256", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Date")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Date", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Credential")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Credential", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-Security-Token")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Security-Token", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-Algorithm")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-Algorithm", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-SignedHeaders", valid_607583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607585: Call_PutJobFailureResult_607573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_607585.validator(path, query, header, formData, body)
  let scheme = call_607585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607585.url(scheme.get, call_607585.host, call_607585.base,
                         call_607585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607585, url, valid)

proc call*(call_607586: Call_PutJobFailureResult_607573; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_607587 = newJObject()
  if body != nil:
    body_607587 = body
  result = call_607586.call(nil, nil, nil, nil, body_607587)

var putJobFailureResult* = Call_PutJobFailureResult_607573(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_607574, base: "/",
    url: url_PutJobFailureResult_607575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_607588 = ref object of OpenApiRestCall_606589
proc url_PutJobSuccessResult_607590(protocol: Scheme; host: string; base: string;
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

proc validate_PutJobSuccessResult_607589(path: JsonNode; query: JsonNode;
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
  var valid_607591 = header.getOrDefault("X-Amz-Target")
  valid_607591 = validateParameter(valid_607591, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_607591 != nil:
    section.add "X-Amz-Target", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Signature")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Signature", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Content-Sha256", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Date")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Date", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Credential")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Credential", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-Security-Token")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-Security-Token", valid_607596
  var valid_607597 = header.getOrDefault("X-Amz-Algorithm")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "X-Amz-Algorithm", valid_607597
  var valid_607598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "X-Amz-SignedHeaders", valid_607598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607600: Call_PutJobSuccessResult_607588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_607600.validator(path, query, header, formData, body)
  let scheme = call_607600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607600.url(scheme.get, call_607600.host, call_607600.base,
                         call_607600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607600, url, valid)

proc call*(call_607601: Call_PutJobSuccessResult_607588; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_607602 = newJObject()
  if body != nil:
    body_607602 = body
  result = call_607601.call(nil, nil, nil, nil, body_607602)

var putJobSuccessResult* = Call_PutJobSuccessResult_607588(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_607589, base: "/",
    url: url_PutJobSuccessResult_607590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_607603 = ref object of OpenApiRestCall_606589
proc url_PutThirdPartyJobFailureResult_607605(protocol: Scheme; host: string;
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

proc validate_PutThirdPartyJobFailureResult_607604(path: JsonNode; query: JsonNode;
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
  var valid_607606 = header.getOrDefault("X-Amz-Target")
  valid_607606 = validateParameter(valid_607606, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_607606 != nil:
    section.add "X-Amz-Target", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Signature")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Signature", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Content-Sha256", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Date")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Date", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Credential")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Credential", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-Security-Token")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Security-Token", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Algorithm")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Algorithm", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-SignedHeaders", valid_607613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607615: Call_PutThirdPartyJobFailureResult_607603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_607615.validator(path, query, header, formData, body)
  let scheme = call_607615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607615.url(scheme.get, call_607615.host, call_607615.base,
                         call_607615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607615, url, valid)

proc call*(call_607616: Call_PutThirdPartyJobFailureResult_607603; body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_607617 = newJObject()
  if body != nil:
    body_607617 = body
  result = call_607616.call(nil, nil, nil, nil, body_607617)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_607603(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_607604, base: "/",
    url: url_PutThirdPartyJobFailureResult_607605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_607618 = ref object of OpenApiRestCall_606589
proc url_PutThirdPartyJobSuccessResult_607620(protocol: Scheme; host: string;
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

proc validate_PutThirdPartyJobSuccessResult_607619(path: JsonNode; query: JsonNode;
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
  var valid_607621 = header.getOrDefault("X-Amz-Target")
  valid_607621 = validateParameter(valid_607621, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_607621 != nil:
    section.add "X-Amz-Target", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Signature")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Signature", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Content-Sha256", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Date")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Date", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Credential")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Credential", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Security-Token")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Security-Token", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Algorithm")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Algorithm", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-SignedHeaders", valid_607628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607630: Call_PutThirdPartyJobSuccessResult_607618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_607630.validator(path, query, header, formData, body)
  let scheme = call_607630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607630.url(scheme.get, call_607630.host, call_607630.base,
                         call_607630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607630, url, valid)

proc call*(call_607631: Call_PutThirdPartyJobSuccessResult_607618; body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_607632 = newJObject()
  if body != nil:
    body_607632 = body
  result = call_607631.call(nil, nil, nil, nil, body_607632)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_607618(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_607619, base: "/",
    url: url_PutThirdPartyJobSuccessResult_607620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_607633 = ref object of OpenApiRestCall_606589
proc url_PutWebhook_607635(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutWebhook_607634(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607636 = header.getOrDefault("X-Amz-Target")
  valid_607636 = validateParameter(valid_607636, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_607636 != nil:
    section.add "X-Amz-Target", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Signature")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Signature", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Content-Sha256", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Date")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Date", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Credential")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Credential", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Security-Token")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Security-Token", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Algorithm")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Algorithm", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-SignedHeaders", valid_607643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607645: Call_PutWebhook_607633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_607645.validator(path, query, header, formData, body)
  let scheme = call_607645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607645.url(scheme.get, call_607645.host, call_607645.base,
                         call_607645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607645, url, valid)

proc call*(call_607646: Call_PutWebhook_607633; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_607647 = newJObject()
  if body != nil:
    body_607647 = body
  result = call_607646.call(nil, nil, nil, nil, body_607647)

var putWebhook* = Call_PutWebhook_607633(name: "putWebhook",
                                      meth: HttpMethod.HttpPost,
                                      host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                      validator: validate_PutWebhook_607634,
                                      base: "/", url: url_PutWebhook_607635,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_607648 = ref object of OpenApiRestCall_606589
proc url_RegisterWebhookWithThirdParty_607650(protocol: Scheme; host: string;
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

proc validate_RegisterWebhookWithThirdParty_607649(path: JsonNode; query: JsonNode;
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
  var valid_607651 = header.getOrDefault("X-Amz-Target")
  valid_607651 = validateParameter(valid_607651, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_607651 != nil:
    section.add "X-Amz-Target", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Signature")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Signature", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-Content-Sha256", valid_607653
  var valid_607654 = header.getOrDefault("X-Amz-Date")
  valid_607654 = validateParameter(valid_607654, JString, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "X-Amz-Date", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Credential")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Credential", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-Security-Token")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Security-Token", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Algorithm")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Algorithm", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-SignedHeaders", valid_607658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607660: Call_RegisterWebhookWithThirdParty_607648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_607660.validator(path, query, header, formData, body)
  let scheme = call_607660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607660.url(scheme.get, call_607660.host, call_607660.base,
                         call_607660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607660, url, valid)

proc call*(call_607661: Call_RegisterWebhookWithThirdParty_607648; body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_607662 = newJObject()
  if body != nil:
    body_607662 = body
  result = call_607661.call(nil, nil, nil, nil, body_607662)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_607648(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_607649, base: "/",
    url: url_RegisterWebhookWithThirdParty_607650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_607663 = ref object of OpenApiRestCall_606589
proc url_RetryStageExecution_607665(protocol: Scheme; host: string; base: string;
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

proc validate_RetryStageExecution_607664(path: JsonNode; query: JsonNode;
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
  var valid_607666 = header.getOrDefault("X-Amz-Target")
  valid_607666 = validateParameter(valid_607666, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_607666 != nil:
    section.add "X-Amz-Target", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Signature")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Signature", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-Content-Sha256", valid_607668
  var valid_607669 = header.getOrDefault("X-Amz-Date")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "X-Amz-Date", valid_607669
  var valid_607670 = header.getOrDefault("X-Amz-Credential")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Credential", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-Security-Token")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-Security-Token", valid_607671
  var valid_607672 = header.getOrDefault("X-Amz-Algorithm")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "X-Amz-Algorithm", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-SignedHeaders", valid_607673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607675: Call_RetryStageExecution_607663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ## 
  let valid = call_607675.validator(path, query, header, formData, body)
  let scheme = call_607675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607675.url(scheme.get, call_607675.host, call_607675.base,
                         call_607675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607675, url, valid)

proc call*(call_607676: Call_RetryStageExecution_607663; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ##   body: JObject (required)
  var body_607677 = newJObject()
  if body != nil:
    body_607677 = body
  result = call_607676.call(nil, nil, nil, nil, body_607677)

var retryStageExecution* = Call_RetryStageExecution_607663(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_607664, base: "/",
    url: url_RetryStageExecution_607665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_607678 = ref object of OpenApiRestCall_606589
proc url_StartPipelineExecution_607680(protocol: Scheme; host: string; base: string;
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

proc validate_StartPipelineExecution_607679(path: JsonNode; query: JsonNode;
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
  var valid_607681 = header.getOrDefault("X-Amz-Target")
  valid_607681 = validateParameter(valid_607681, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_607681 != nil:
    section.add "X-Amz-Target", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Signature")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Signature", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Content-Sha256", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Date")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Date", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-Credential")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-Credential", valid_607685
  var valid_607686 = header.getOrDefault("X-Amz-Security-Token")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "X-Amz-Security-Token", valid_607686
  var valid_607687 = header.getOrDefault("X-Amz-Algorithm")
  valid_607687 = validateParameter(valid_607687, JString, required = false,
                                 default = nil)
  if valid_607687 != nil:
    section.add "X-Amz-Algorithm", valid_607687
  var valid_607688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607688 = validateParameter(valid_607688, JString, required = false,
                                 default = nil)
  if valid_607688 != nil:
    section.add "X-Amz-SignedHeaders", valid_607688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607690: Call_StartPipelineExecution_607678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_607690.validator(path, query, header, formData, body)
  let scheme = call_607690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607690.url(scheme.get, call_607690.host, call_607690.base,
                         call_607690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607690, url, valid)

proc call*(call_607691: Call_StartPipelineExecution_607678; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_607692 = newJObject()
  if body != nil:
    body_607692 = body
  result = call_607691.call(nil, nil, nil, nil, body_607692)

var startPipelineExecution* = Call_StartPipelineExecution_607678(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_607679, base: "/",
    url: url_StartPipelineExecution_607680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopPipelineExecution_607693 = ref object of OpenApiRestCall_606589
proc url_StopPipelineExecution_607695(protocol: Scheme; host: string; base: string;
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

proc validate_StopPipelineExecution_607694(path: JsonNode; query: JsonNode;
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
  var valid_607696 = header.getOrDefault("X-Amz-Target")
  valid_607696 = validateParameter(valid_607696, JString, required = true, default = newJString(
      "CodePipeline_20150709.StopPipelineExecution"))
  if valid_607696 != nil:
    section.add "X-Amz-Target", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Signature")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Signature", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Content-Sha256", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Date")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Date", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Credential")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Credential", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-Security-Token")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-Security-Token", valid_607701
  var valid_607702 = header.getOrDefault("X-Amz-Algorithm")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Algorithm", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-SignedHeaders", valid_607703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607705: Call_StopPipelineExecution_607693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ## 
  let valid = call_607705.validator(path, query, header, formData, body)
  let scheme = call_607705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607705.url(scheme.get, call_607705.host, call_607705.base,
                         call_607705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607705, url, valid)

proc call*(call_607706: Call_StopPipelineExecution_607693; body: JsonNode): Recallable =
  ## stopPipelineExecution
  ## Stops the specified pipeline execution. You choose to either stop the pipeline execution by completing in-progress actions without starting subsequent actions, or by abandoning in-progress actions. While completing or abandoning in-progress actions, the pipeline execution is in a <code>Stopping</code> state. After all in-progress actions are completed or abandoned, the pipeline execution is in a <code>Stopped</code> state.
  ##   body: JObject (required)
  var body_607707 = newJObject()
  if body != nil:
    body_607707 = body
  result = call_607706.call(nil, nil, nil, nil, body_607707)

var stopPipelineExecution* = Call_StopPipelineExecution_607693(
    name: "stopPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StopPipelineExecution",
    validator: validate_StopPipelineExecution_607694, base: "/",
    url: url_StopPipelineExecution_607695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607708 = ref object of OpenApiRestCall_606589
proc url_TagResource_607710(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607711 = header.getOrDefault("X-Amz-Target")
  valid_607711 = validateParameter(valid_607711, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_607711 != nil:
    section.add "X-Amz-Target", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Signature")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Signature", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Content-Sha256", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Date")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Date", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-Credential")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-Credential", valid_607715
  var valid_607716 = header.getOrDefault("X-Amz-Security-Token")
  valid_607716 = validateParameter(valid_607716, JString, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "X-Amz-Security-Token", valid_607716
  var valid_607717 = header.getOrDefault("X-Amz-Algorithm")
  valid_607717 = validateParameter(valid_607717, JString, required = false,
                                 default = nil)
  if valid_607717 != nil:
    section.add "X-Amz-Algorithm", valid_607717
  var valid_607718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607718 = validateParameter(valid_607718, JString, required = false,
                                 default = nil)
  if valid_607718 != nil:
    section.add "X-Amz-SignedHeaders", valid_607718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607720: Call_TagResource_607708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_607720.validator(path, query, header, formData, body)
  let scheme = call_607720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607720.url(scheme.get, call_607720.host, call_607720.base,
                         call_607720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607720, url, valid)

proc call*(call_607721: Call_TagResource_607708; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_607722 = newJObject()
  if body != nil:
    body_607722 = body
  result = call_607721.call(nil, nil, nil, nil, body_607722)

var tagResource* = Call_TagResource_607708(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
                                        validator: validate_TagResource_607709,
                                        base: "/", url: url_TagResource_607710,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607723 = ref object of OpenApiRestCall_606589
proc url_UntagResource_607725(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607724(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607726 = header.getOrDefault("X-Amz-Target")
  valid_607726 = validateParameter(valid_607726, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_607726 != nil:
    section.add "X-Amz-Target", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Signature")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Signature", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Content-Sha256", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-Date")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-Date", valid_607729
  var valid_607730 = header.getOrDefault("X-Amz-Credential")
  valid_607730 = validateParameter(valid_607730, JString, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "X-Amz-Credential", valid_607730
  var valid_607731 = header.getOrDefault("X-Amz-Security-Token")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-Security-Token", valid_607731
  var valid_607732 = header.getOrDefault("X-Amz-Algorithm")
  valid_607732 = validateParameter(valid_607732, JString, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "X-Amz-Algorithm", valid_607732
  var valid_607733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607733 = validateParameter(valid_607733, JString, required = false,
                                 default = nil)
  if valid_607733 != nil:
    section.add "X-Amz-SignedHeaders", valid_607733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607735: Call_UntagResource_607723; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_607735.validator(path, query, header, formData, body)
  let scheme = call_607735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607735.url(scheme.get, call_607735.host, call_607735.base,
                         call_607735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607735, url, valid)

proc call*(call_607736: Call_UntagResource_607723; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_607737 = newJObject()
  if body != nil:
    body_607737 = body
  result = call_607736.call(nil, nil, nil, nil, body_607737)

var untagResource* = Call_UntagResource_607723(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_607724, base: "/", url: url_UntagResource_607725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_607738 = ref object of OpenApiRestCall_606589
proc url_UpdatePipeline_607740(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_607739(path: JsonNode; query: JsonNode;
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
  var valid_607741 = header.getOrDefault("X-Amz-Target")
  valid_607741 = validateParameter(valid_607741, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_607741 != nil:
    section.add "X-Amz-Target", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Signature")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Signature", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Content-Sha256", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Date")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Date", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Credential")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Credential", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-Security-Token")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Security-Token", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-Algorithm")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-Algorithm", valid_607747
  var valid_607748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607748 = validateParameter(valid_607748, JString, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "X-Amz-SignedHeaders", valid_607748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607750: Call_UpdatePipeline_607738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_607750.validator(path, query, header, formData, body)
  let scheme = call_607750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607750.url(scheme.get, call_607750.host, call_607750.base,
                         call_607750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607750, url, valid)

proc call*(call_607751: Call_UpdatePipeline_607738; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_607752 = newJObject()
  if body != nil:
    body_607752 = body
  result = call_607751.call(nil, nil, nil, nil, body_607752)

var updatePipeline* = Call_UpdatePipeline_607738(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_607739, base: "/", url: url_UpdatePipeline_607740,
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
