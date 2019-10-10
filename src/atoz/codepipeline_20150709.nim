
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodePipeline
## version: 2015-07-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodePipeline</fullname> <p> <b>Overview</b> </p> <p>This is the AWS CodePipeline API Reference. This guide provides descriptions of the actions and data types for AWS CodePipeline. Some functionality for your pipeline can only be configured through the API. For more information, see the <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html">AWS CodePipeline User Guide</a>.</p> <p>You can use the AWS CodePipeline API to work with pipelines, stages, actions, and transitions.</p> <p> <i>Pipelines</i> are models of automated release processes. Each pipeline is uniquely named, and consists of stages, actions, and transitions. </p> <p>You can work with pipelines by calling:</p> <ul> <li> <p> <a>CreatePipeline</a>, which creates a uniquely named pipeline.</p> </li> <li> <p> <a>DeletePipeline</a>, which deletes the specified pipeline.</p> </li> <li> <p> <a>GetPipeline</a>, which returns information about the pipeline structure and pipeline metadata, including the pipeline Amazon Resource Name (ARN).</p> </li> <li> <p> <a>GetPipelineExecution</a>, which returns information about a specific execution of a pipeline.</p> </li> <li> <p> <a>GetPipelineState</a>, which returns information about the current state of the stages and actions of a pipeline.</p> </li> <li> <p> <a>ListActionExecutions</a>, which returns action-level details for past executions. The details include full stage and action-level details, including individual action duration, status, any errors that occurred during the execution, and input and output artifact location details.</p> </li> <li> <p> <a>ListPipelines</a>, which gets a summary of all of the pipelines associated with your account.</p> </li> <li> <p> <a>ListPipelineExecutions</a>, which gets a summary of the most recent executions for a pipeline.</p> </li> <li> <p> <a>StartPipelineExecution</a>, which runs the most recent revision of an artifact through the pipeline.</p> </li> <li> <p> <a>UpdatePipeline</a>, which updates a pipeline with edits or changes to the structure of the pipeline.</p> </li> </ul> <p>Pipelines include <i>stages</i>. Each stage contains one or more actions that must complete before the next stage begins. A stage results in success or failure. If a stage fails, the pipeline stops at that stage and remains stopped until either a new version of an artifact appears in the source location, or a user takes action to rerun the most recent artifact through the pipeline. You can call <a>GetPipelineState</a>, which displays the status of a pipeline, including the status of stages in the pipeline, or <a>GetPipeline</a>, which returns the entire structure of the pipeline, including the stages of that pipeline. For more information about the structure of stages and actions, see <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-structure.html">AWS CodePipeline Pipeline Structure Reference</a>.</p> <p>Pipeline stages include <i>actions</i> that are categorized into categories such as source or build actions performed in a stage of a pipeline. For example, you can use a source action to import artifacts into a pipeline from a source such as Amazon S3. Like stages, you do not work with actions directly in most cases, but you do define and interact with actions when working with pipeline operations such as <a>CreatePipeline</a> and <a>GetPipelineState</a>. Valid action categories are:</p> <ul> <li> <p>Source</p> </li> <li> <p>Build</p> </li> <li> <p>Test</p> </li> <li> <p>Deploy</p> </li> <li> <p>Approval</p> </li> <li> <p>Invoke</p> </li> </ul> <p>Pipelines also include <i>transitions</i>, which allow the transition of artifacts from one stage to the next in a pipeline after the actions in one stage complete.</p> <p>You can work with transitions by calling:</p> <ul> <li> <p> <a>DisableStageTransition</a>, which prevents artifacts from transitioning to the next stage in a pipeline.</p> </li> <li> <p> <a>EnableStageTransition</a>, which enables transition of artifacts between stages in a pipeline. </p> </li> </ul> <p> <b>Using the API to integrate with AWS CodePipeline</b> </p> <p>For third-party integrators or developers who want to create their own integrations with AWS CodePipeline, the expected sequence varies from the standard API user. To integrate with AWS CodePipeline, developers need to work with the following items:</p> <p> <b>Jobs</b>, which are instances of an action. For example, a job for a source action might import a revision of an artifact from a source. </p> <p>You can work with jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeJob</a>, which confirms whether a job worker has received the specified job.</p> </li> <li> <p> <a>GetJobDetails</a>, which returns the details of a job.</p> </li> <li> <p> <a>PollForJobs</a>, which determines whether there are any jobs to act on.</p> </li> <li> <p> <a>PutJobFailureResult</a>, which provides details of a job failure. </p> </li> <li> <p> <a>PutJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul> <p> <b>Third party jobs</b>, which are instances of an action created by a partner action and integrated into AWS CodePipeline. Partner actions are created by members of the AWS Partner Network.</p> <p>You can work with third party jobs by calling:</p> <ul> <li> <p> <a>AcknowledgeThirdPartyJob</a>, which confirms whether a job worker has received the specified job.</p> </li> <li> <p> <a>GetThirdPartyJobDetails</a>, which requests the details of a job for a partner action.</p> </li> <li> <p> <a>PollForThirdPartyJobs</a>, which determines whether there are any jobs to act on. </p> </li> <li> <p> <a>PutThirdPartyJobFailureResult</a>, which provides details of a job failure.</p> </li> <li> <p> <a>PutThirdPartyJobSuccessResult</a>, which provides details of a job success.</p> </li> </ul>
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcknowledgeJob_602803 = ref object of OpenApiRestCall_602466
proc url_AcknowledgeJob_602805(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcknowledgeJob_602804(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AcknowledgeJob_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AcknowledgeJob_602803; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var acknowledgeJob* = Call_AcknowledgeJob_602803(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_602804, base: "/", url: url_AcknowledgeJob_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_603072 = ref object of OpenApiRestCall_602466
proc url_AcknowledgeThirdPartyJob_603074(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcknowledgeThirdPartyJob_603073(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_AcknowledgeThirdPartyJob_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AcknowledgeThirdPartyJob_603072; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_603072(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_603073, base: "/",
    url: url_AcknowledgeThirdPartyJob_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_603087 = ref object of OpenApiRestCall_602466
proc url_CreateCustomActionType_603089(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCustomActionType_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateCustomActionType_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateCustomActionType_603087; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createCustomActionType* = Call_CreateCustomActionType_603087(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_603088, base: "/",
    url: url_CreateCustomActionType_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_603102 = ref object of OpenApiRestCall_602466
proc url_CreatePipeline_603104(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreatePipeline_603102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreatePipeline_603102; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createPipeline* = Call_CreatePipeline_603102(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_603103, base: "/", url: url_CreatePipeline_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_603117 = ref object of OpenApiRestCall_602466
proc url_DeleteCustomActionType_603119(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCustomActionType_603118(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeleteCustomActionType_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeleteCustomActionType_603117; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deleteCustomActionType* = Call_DeleteCustomActionType_603117(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_603118, base: "/",
    url: url_DeleteCustomActionType_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_603132 = ref object of OpenApiRestCall_602466
proc url_DeletePipeline_603134(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePipeline_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DeletePipeline_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DeletePipeline_603132; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var deletePipeline* = Call_DeletePipeline_603132(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_603133, base: "/", url: url_DeletePipeline_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_603147 = ref object of OpenApiRestCall_602466
proc url_DeleteWebhook_603149(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWebhook_603148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DeleteWebhook_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DeleteWebhook_603147; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var deleteWebhook* = Call_DeleteWebhook_603147(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_603148, base: "/", url: url_DeleteWebhook_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_603162 = ref object of OpenApiRestCall_602466
proc url_DeregisterWebhookWithThirdParty_603164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterWebhookWithThirdParty_603163(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeregisterWebhookWithThirdParty_603162;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeregisterWebhookWithThirdParty_603162; body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_603162(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_603163, base: "/",
    url: url_DeregisterWebhookWithThirdParty_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_603177 = ref object of OpenApiRestCall_602466
proc url_DisableStageTransition_603179(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableStageTransition_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DisableStageTransition_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DisableStageTransition_603177; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var disableStageTransition* = Call_DisableStageTransition_603177(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_603178, base: "/",
    url: url_DisableStageTransition_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_603192 = ref object of OpenApiRestCall_602466
proc url_EnableStageTransition_603194(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableStageTransition_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_EnableStageTransition_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_EnableStageTransition_603192; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var enableStageTransition* = Call_EnableStageTransition_603192(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_603193, base: "/",
    url: url_EnableStageTransition_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_603207 = ref object of OpenApiRestCall_602466
proc url_GetJobDetails_603209(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobDetails_603208(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_GetJobDetails_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_GetJobDetails_603207; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var getJobDetails* = Call_GetJobDetails_603207(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_603208, base: "/", url: url_GetJobDetails_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_603222 = ref object of OpenApiRestCall_602466
proc url_GetPipeline_603224(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPipeline_603223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_GetPipeline_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_GetPipeline_603222; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var getPipeline* = Call_GetPipeline_603222(name: "getPipeline",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
                                        validator: validate_GetPipeline_603223,
                                        base: "/", url: url_GetPipeline_603224,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_603237 = ref object of OpenApiRestCall_602466
proc url_GetPipelineExecution_603239(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPipelineExecution_603238(path: JsonNode; query: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_GetPipelineExecution_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_GetPipelineExecution_603237; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var getPipelineExecution* = Call_GetPipelineExecution_603237(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_603238, base: "/",
    url: url_GetPipelineExecution_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_603252 = ref object of OpenApiRestCall_602466
proc url_GetPipelineState_603254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPipelineState_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_GetPipelineState_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_GetPipelineState_603252; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var getPipelineState* = Call_GetPipelineState_603252(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_603253, base: "/",
    url: url_GetPipelineState_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_603267 = ref object of OpenApiRestCall_602466
proc url_GetThirdPartyJobDetails_603269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetThirdPartyJobDetails_603268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_GetThirdPartyJobDetails_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_GetThirdPartyJobDetails_603267; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_603267(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_603268, base: "/",
    url: url_GetThirdPartyJobDetails_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_603282 = ref object of OpenApiRestCall_602466
proc url_ListActionExecutions_603284(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListActionExecutions_603283(path: JsonNode; query: JsonNode;
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
  var valid_603285 = query.getOrDefault("maxResults")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "maxResults", valid_603285
  var valid_603286 = query.getOrDefault("nextToken")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "nextToken", valid_603286
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
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603289 = header.getOrDefault("X-Amz-Target")
  valid_603289 = validateParameter(valid_603289, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionExecutions"))
  if valid_603289 != nil:
    section.add "X-Amz-Target", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Content-Sha256", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Algorithm")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Algorithm", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Signature")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Signature", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-SignedHeaders", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Credential")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Credential", valid_603294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603296: Call_ListActionExecutions_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_603296.validator(path, query, header, formData, body)
  let scheme = call_603296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603296.url(scheme.get, call_603296.host, call_603296.base,
                         call_603296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603296, url, valid)

proc call*(call_603297: Call_ListActionExecutions_603282; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603298 = newJObject()
  var body_603299 = newJObject()
  add(query_603298, "maxResults", newJString(maxResults))
  add(query_603298, "nextToken", newJString(nextToken))
  if body != nil:
    body_603299 = body
  result = call_603297.call(nil, query_603298, nil, nil, body_603299)

var listActionExecutions* = Call_ListActionExecutions_603282(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_603283, base: "/",
    url: url_ListActionExecutions_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_603301 = ref object of OpenApiRestCall_602466
proc url_ListActionTypes_603303(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListActionTypes_603302(path: JsonNode; query: JsonNode;
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
  var valid_603304 = query.getOrDefault("nextToken")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "nextToken", valid_603304
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
  var valid_603305 = header.getOrDefault("X-Amz-Date")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Date", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Security-Token")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Security-Token", valid_603306
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603307 = header.getOrDefault("X-Amz-Target")
  valid_603307 = validateParameter(valid_603307, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_603307 != nil:
    section.add "X-Amz-Target", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Content-Sha256", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Algorithm")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Algorithm", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-SignedHeaders", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Credential")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Credential", valid_603312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603314: Call_ListActionTypes_603301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_603314.validator(path, query, header, formData, body)
  let scheme = call_603314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603314.url(scheme.get, call_603314.host, call_603314.base,
                         call_603314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603314, url, valid)

proc call*(call_603315: Call_ListActionTypes_603301; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603316 = newJObject()
  var body_603317 = newJObject()
  add(query_603316, "nextToken", newJString(nextToken))
  if body != nil:
    body_603317 = body
  result = call_603315.call(nil, query_603316, nil, nil, body_603317)

var listActionTypes* = Call_ListActionTypes_603301(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_603302, base: "/", url: url_ListActionTypes_603303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_603318 = ref object of OpenApiRestCall_602466
proc url_ListPipelineExecutions_603320(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelineExecutions_603319(path: JsonNode; query: JsonNode;
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
  var valid_603321 = query.getOrDefault("maxResults")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "maxResults", valid_603321
  var valid_603322 = query.getOrDefault("nextToken")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "nextToken", valid_603322
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
  var valid_603323 = header.getOrDefault("X-Amz-Date")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Date", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Security-Token")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Security-Token", valid_603324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603325 = header.getOrDefault("X-Amz-Target")
  valid_603325 = validateParameter(valid_603325, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_603325 != nil:
    section.add "X-Amz-Target", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Content-Sha256", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Algorithm")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Algorithm", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Signature")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Signature", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-SignedHeaders", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Credential")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Credential", valid_603330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603332: Call_ListPipelineExecutions_603318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_603332.validator(path, query, header, formData, body)
  let scheme = call_603332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603332.url(scheme.get, call_603332.host, call_603332.base,
                         call_603332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603332, url, valid)

proc call*(call_603333: Call_ListPipelineExecutions_603318; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603334 = newJObject()
  var body_603335 = newJObject()
  add(query_603334, "maxResults", newJString(maxResults))
  add(query_603334, "nextToken", newJString(nextToken))
  if body != nil:
    body_603335 = body
  result = call_603333.call(nil, query_603334, nil, nil, body_603335)

var listPipelineExecutions* = Call_ListPipelineExecutions_603318(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_603319, base: "/",
    url: url_ListPipelineExecutions_603320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_603336 = ref object of OpenApiRestCall_602466
proc url_ListPipelines_603338(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_603337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603339 = query.getOrDefault("nextToken")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "nextToken", valid_603339
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
  var valid_603340 = header.getOrDefault("X-Amz-Date")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Date", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Security-Token")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Security-Token", valid_603341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603342 = header.getOrDefault("X-Amz-Target")
  valid_603342 = validateParameter(valid_603342, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_603342 != nil:
    section.add "X-Amz-Target", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Content-Sha256", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Algorithm")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Algorithm", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Signature")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Signature", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-SignedHeaders", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Credential")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Credential", valid_603347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603349: Call_ListPipelines_603336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_603349.validator(path, query, header, formData, body)
  let scheme = call_603349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603349.url(scheme.get, call_603349.host, call_603349.base,
                         call_603349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603349, url, valid)

proc call*(call_603350: Call_ListPipelines_603336; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603351 = newJObject()
  var body_603352 = newJObject()
  add(query_603351, "nextToken", newJString(nextToken))
  if body != nil:
    body_603352 = body
  result = call_603350.call(nil, query_603351, nil, nil, body_603352)

var listPipelines* = Call_ListPipelines_603336(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_603337, base: "/", url: url_ListPipelines_603338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603353 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603355(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603354(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_603356 = query.getOrDefault("maxResults")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "maxResults", valid_603356
  var valid_603357 = query.getOrDefault("nextToken")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "nextToken", valid_603357
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603360 = header.getOrDefault("X-Amz-Target")
  valid_603360 = validateParameter(valid_603360, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_603360 != nil:
    section.add "X-Amz-Target", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_ListTagsForResource_603353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_ListTagsForResource_603353; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603369 = newJObject()
  var body_603370 = newJObject()
  add(query_603369, "maxResults", newJString(maxResults))
  add(query_603369, "nextToken", newJString(nextToken))
  if body != nil:
    body_603370 = body
  result = call_603368.call(nil, query_603369, nil, nil, body_603370)

var listTagsForResource* = Call_ListTagsForResource_603353(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_603354, base: "/",
    url: url_ListTagsForResource_603355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_603371 = ref object of OpenApiRestCall_602466
proc url_ListWebhooks_603373(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebhooks_603372(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603374 = query.getOrDefault("NextToken")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "NextToken", valid_603374
  var valid_603375 = query.getOrDefault("MaxResults")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "MaxResults", valid_603375
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
  var valid_603376 = header.getOrDefault("X-Amz-Date")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Date", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603378 = header.getOrDefault("X-Amz-Target")
  valid_603378 = validateParameter(valid_603378, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_603378 != nil:
    section.add "X-Amz-Target", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Content-Sha256", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Algorithm")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Algorithm", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Signature")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Signature", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-SignedHeaders", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Credential")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Credential", valid_603383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603385: Call_ListWebhooks_603371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  let valid = call_603385.validator(path, query, header, formData, body)
  let scheme = call_603385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603385.url(scheme.get, call_603385.host, call_603385.base,
                         call_603385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603385, url, valid)

proc call*(call_603386: Call_ListWebhooks_603371; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603387 = newJObject()
  var body_603388 = newJObject()
  add(query_603387, "NextToken", newJString(NextToken))
  if body != nil:
    body_603388 = body
  add(query_603387, "MaxResults", newJString(MaxResults))
  result = call_603386.call(nil, query_603387, nil, nil, body_603388)

var listWebhooks* = Call_ListWebhooks_603371(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_603372, base: "/", url: url_ListWebhooks_603373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_603389 = ref object of OpenApiRestCall_602466
proc url_PollForJobs_603391(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PollForJobs_603390(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
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
  var valid_603392 = header.getOrDefault("X-Amz-Date")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Date", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Security-Token")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Security-Token", valid_603393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603394 = header.getOrDefault("X-Amz-Target")
  valid_603394 = validateParameter(valid_603394, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_603394 != nil:
    section.add "X-Amz-Target", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Content-Sha256", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Algorithm")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Algorithm", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Signature")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Signature", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-SignedHeaders", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Credential")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Credential", valid_603399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603401: Call_PollForJobs_603389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_603401.validator(path, query, header, formData, body)
  let scheme = call_603401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603401.url(scheme.get, call_603401.host, call_603401.base,
                         call_603401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603401, url, valid)

proc call*(call_603402: Call_PollForJobs_603389; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_603403 = newJObject()
  if body != nil:
    body_603403 = body
  result = call_603402.call(nil, nil, nil, nil, body_603403)

var pollForJobs* = Call_PollForJobs_603389(name: "pollForJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
                                        validator: validate_PollForJobs_603390,
                                        base: "/", url: url_PollForJobs_603391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_603404 = ref object of OpenApiRestCall_602466
proc url_PollForThirdPartyJobs_603406(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PollForThirdPartyJobs_603405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
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
  var valid_603407 = header.getOrDefault("X-Amz-Date")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Date", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Security-Token")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Security-Token", valid_603408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603409 = header.getOrDefault("X-Amz-Target")
  valid_603409 = validateParameter(valid_603409, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_603409 != nil:
    section.add "X-Amz-Target", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Algorithm")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Algorithm", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Signature")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Signature", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-SignedHeaders", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603416: Call_PollForThirdPartyJobs_603404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_603416.validator(path, query, header, formData, body)
  let scheme = call_603416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603416.url(scheme.get, call_603416.host, call_603416.base,
                         call_603416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603416, url, valid)

proc call*(call_603417: Call_PollForThirdPartyJobs_603404; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_603418 = newJObject()
  if body != nil:
    body_603418 = body
  result = call_603417.call(nil, nil, nil, nil, body_603418)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_603404(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_603405, base: "/",
    url: url_PollForThirdPartyJobs_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_603419 = ref object of OpenApiRestCall_602466
proc url_PutActionRevision_603421(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutActionRevision_603420(path: JsonNode; query: JsonNode;
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603424 = header.getOrDefault("X-Amz-Target")
  valid_603424 = validateParameter(valid_603424, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_603424 != nil:
    section.add "X-Amz-Target", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Algorithm")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Algorithm", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Signature")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Signature", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-SignedHeaders", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_PutActionRevision_603419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603431, url, valid)

proc call*(call_603432: Call_PutActionRevision_603419; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_603433 = newJObject()
  if body != nil:
    body_603433 = body
  result = call_603432.call(nil, nil, nil, nil, body_603433)

var putActionRevision* = Call_PutActionRevision_603419(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_603420, base: "/",
    url: url_PutActionRevision_603421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_603434 = ref object of OpenApiRestCall_602466
proc url_PutApprovalResult_603436(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutApprovalResult_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Security-Token")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Security-Token", valid_603438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603439 = header.getOrDefault("X-Amz-Target")
  valid_603439 = validateParameter(valid_603439, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_603439 != nil:
    section.add "X-Amz-Target", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Content-Sha256", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Algorithm")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Algorithm", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Signature")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Signature", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-SignedHeaders", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Credential")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Credential", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_PutApprovalResult_603434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603446, url, valid)

proc call*(call_603447: Call_PutApprovalResult_603434; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_603448 = newJObject()
  if body != nil:
    body_603448 = body
  result = call_603447.call(nil, nil, nil, nil, body_603448)

var putApprovalResult* = Call_PutApprovalResult_603434(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_603435, base: "/",
    url: url_PutApprovalResult_603436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_603449 = ref object of OpenApiRestCall_602466
proc url_PutJobFailureResult_603451(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutJobFailureResult_603450(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603452 = header.getOrDefault("X-Amz-Date")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Date", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Security-Token")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Security-Token", valid_603453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603454 = header.getOrDefault("X-Amz-Target")
  valid_603454 = validateParameter(valid_603454, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_603454 != nil:
    section.add "X-Amz-Target", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Content-Sha256", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Algorithm")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Algorithm", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Signature")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Signature", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-SignedHeaders", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Credential")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Credential", valid_603459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603461: Call_PutJobFailureResult_603449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_603461.validator(path, query, header, formData, body)
  let scheme = call_603461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603461.url(scheme.get, call_603461.host, call_603461.base,
                         call_603461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603461, url, valid)

proc call*(call_603462: Call_PutJobFailureResult_603449; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_603463 = newJObject()
  if body != nil:
    body_603463 = body
  result = call_603462.call(nil, nil, nil, nil, body_603463)

var putJobFailureResult* = Call_PutJobFailureResult_603449(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_603450, base: "/",
    url: url_PutJobFailureResult_603451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_603464 = ref object of OpenApiRestCall_602466
proc url_PutJobSuccessResult_603466(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutJobSuccessResult_603465(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603467 = header.getOrDefault("X-Amz-Date")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Date", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Security-Token")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Security-Token", valid_603468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603469 = header.getOrDefault("X-Amz-Target")
  valid_603469 = validateParameter(valid_603469, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_603469 != nil:
    section.add "X-Amz-Target", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Content-Sha256", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Algorithm")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Algorithm", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Signature")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Signature", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-SignedHeaders", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Credential")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Credential", valid_603474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603476: Call_PutJobSuccessResult_603464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_603476.validator(path, query, header, formData, body)
  let scheme = call_603476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603476.url(scheme.get, call_603476.host, call_603476.base,
                         call_603476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603476, url, valid)

proc call*(call_603477: Call_PutJobSuccessResult_603464; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_603478 = newJObject()
  if body != nil:
    body_603478 = body
  result = call_603477.call(nil, nil, nil, nil, body_603478)

var putJobSuccessResult* = Call_PutJobSuccessResult_603464(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_603465, base: "/",
    url: url_PutJobSuccessResult_603466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_603479 = ref object of OpenApiRestCall_602466
proc url_PutThirdPartyJobFailureResult_603481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutThirdPartyJobFailureResult_603480(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603482 = header.getOrDefault("X-Amz-Date")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Date", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Security-Token")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Security-Token", valid_603483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603484 = header.getOrDefault("X-Amz-Target")
  valid_603484 = validateParameter(valid_603484, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_603484 != nil:
    section.add "X-Amz-Target", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Content-Sha256", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Algorithm")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Algorithm", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Signature")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Signature", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-SignedHeaders", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Credential")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Credential", valid_603489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603491: Call_PutThirdPartyJobFailureResult_603479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_603491.validator(path, query, header, formData, body)
  let scheme = call_603491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603491.url(scheme.get, call_603491.host, call_603491.base,
                         call_603491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603491, url, valid)

proc call*(call_603492: Call_PutThirdPartyJobFailureResult_603479; body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_603493 = newJObject()
  if body != nil:
    body_603493 = body
  result = call_603492.call(nil, nil, nil, nil, body_603493)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_603479(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_603480, base: "/",
    url: url_PutThirdPartyJobFailureResult_603481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_603494 = ref object of OpenApiRestCall_602466
proc url_PutThirdPartyJobSuccessResult_603496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutThirdPartyJobSuccessResult_603495(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603497 = header.getOrDefault("X-Amz-Date")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Date", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Security-Token")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Security-Token", valid_603498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603499 = header.getOrDefault("X-Amz-Target")
  valid_603499 = validateParameter(valid_603499, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_603499 != nil:
    section.add "X-Amz-Target", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Content-Sha256", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Algorithm")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Algorithm", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Signature")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Signature", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-SignedHeaders", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Credential")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Credential", valid_603504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603506: Call_PutThirdPartyJobSuccessResult_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_603506.validator(path, query, header, formData, body)
  let scheme = call_603506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603506.url(scheme.get, call_603506.host, call_603506.base,
                         call_603506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603506, url, valid)

proc call*(call_603507: Call_PutThirdPartyJobSuccessResult_603494; body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_603508 = newJObject()
  if body != nil:
    body_603508 = body
  result = call_603507.call(nil, nil, nil, nil, body_603508)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_603494(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_603495, base: "/",
    url: url_PutThirdPartyJobSuccessResult_603496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_603509 = ref object of OpenApiRestCall_602466
proc url_PutWebhook_603511(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutWebhook_603510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603512 = header.getOrDefault("X-Amz-Date")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Date", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Security-Token")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Security-Token", valid_603513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603514 = header.getOrDefault("X-Amz-Target")
  valid_603514 = validateParameter(valid_603514, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_603514 != nil:
    section.add "X-Amz-Target", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Content-Sha256", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Algorithm")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Algorithm", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Signature")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Signature", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Credential")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Credential", valid_603519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_PutWebhook_603509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_PutWebhook_603509; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_603523 = newJObject()
  if body != nil:
    body_603523 = body
  result = call_603522.call(nil, nil, nil, nil, body_603523)

var putWebhook* = Call_PutWebhook_603509(name: "putWebhook",
                                      meth: HttpMethod.HttpPost,
                                      host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                      validator: validate_PutWebhook_603510,
                                      base: "/", url: url_PutWebhook_603511,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_603524 = ref object of OpenApiRestCall_602466
proc url_RegisterWebhookWithThirdParty_603526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterWebhookWithThirdParty_603525(path: JsonNode; query: JsonNode;
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
  var valid_603527 = header.getOrDefault("X-Amz-Date")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Date", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Security-Token")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Security-Token", valid_603528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603529 = header.getOrDefault("X-Amz-Target")
  valid_603529 = validateParameter(valid_603529, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_603529 != nil:
    section.add "X-Amz-Target", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Content-Sha256", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Algorithm")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Algorithm", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Signature")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Signature", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-SignedHeaders", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Credential")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Credential", valid_603534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603536: Call_RegisterWebhookWithThirdParty_603524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_603536.validator(path, query, header, formData, body)
  let scheme = call_603536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603536.url(scheme.get, call_603536.host, call_603536.base,
                         call_603536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603536, url, valid)

proc call*(call_603537: Call_RegisterWebhookWithThirdParty_603524; body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_603538 = newJObject()
  if body != nil:
    body_603538 = body
  result = call_603537.call(nil, nil, nil, nil, body_603538)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_603524(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_603525, base: "/",
    url: url_RegisterWebhookWithThirdParty_603526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_603539 = ref object of OpenApiRestCall_602466
proc url_RetryStageExecution_603541(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetryStageExecution_603540(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603542 = header.getOrDefault("X-Amz-Date")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Date", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Security-Token")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Security-Token", valid_603543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603544 = header.getOrDefault("X-Amz-Target")
  valid_603544 = validateParameter(valid_603544, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_603544 != nil:
    section.add "X-Amz-Target", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Content-Sha256", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Algorithm")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Algorithm", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Signature")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Signature", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-SignedHeaders", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Credential")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Credential", valid_603549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603551: Call_RetryStageExecution_603539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ## 
  let valid = call_603551.validator(path, query, header, formData, body)
  let scheme = call_603551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603551.url(scheme.get, call_603551.host, call_603551.base,
                         call_603551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603551, url, valid)

proc call*(call_603552: Call_RetryStageExecution_603539; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ##   body: JObject (required)
  var body_603553 = newJObject()
  if body != nil:
    body_603553 = body
  result = call_603552.call(nil, nil, nil, nil, body_603553)

var retryStageExecution* = Call_RetryStageExecution_603539(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_603540, base: "/",
    url: url_RetryStageExecution_603541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_603554 = ref object of OpenApiRestCall_602466
proc url_StartPipelineExecution_603556(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartPipelineExecution_603555(path: JsonNode; query: JsonNode;
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
  var valid_603557 = header.getOrDefault("X-Amz-Date")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Date", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Security-Token")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Security-Token", valid_603558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603559 = header.getOrDefault("X-Amz-Target")
  valid_603559 = validateParameter(valid_603559, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_603559 != nil:
    section.add "X-Amz-Target", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Content-Sha256", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Algorithm")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Algorithm", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Signature")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Signature", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-SignedHeaders", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Credential")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Credential", valid_603564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603566: Call_StartPipelineExecution_603554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_603566.validator(path, query, header, formData, body)
  let scheme = call_603566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603566.url(scheme.get, call_603566.host, call_603566.base,
                         call_603566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603566, url, valid)

proc call*(call_603567: Call_StartPipelineExecution_603554; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_603568 = newJObject()
  if body != nil:
    body_603568 = body
  result = call_603567.call(nil, nil, nil, nil, body_603568)

var startPipelineExecution* = Call_StartPipelineExecution_603554(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_603555, base: "/",
    url: url_StartPipelineExecution_603556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603569 = ref object of OpenApiRestCall_602466
proc url_TagResource_603571(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603570(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Security-Token")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Security-Token", valid_603573
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603574 = header.getOrDefault("X-Amz-Target")
  valid_603574 = validateParameter(valid_603574, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_603574 != nil:
    section.add "X-Amz-Target", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Content-Sha256", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Algorithm")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Algorithm", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Signature")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Signature", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-SignedHeaders", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Credential")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Credential", valid_603579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603581: Call_TagResource_603569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_603581.validator(path, query, header, formData, body)
  let scheme = call_603581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603581.url(scheme.get, call_603581.host, call_603581.base,
                         call_603581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603581, url, valid)

proc call*(call_603582: Call_TagResource_603569; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_603583 = newJObject()
  if body != nil:
    body_603583 = body
  result = call_603582.call(nil, nil, nil, nil, body_603583)

var tagResource* = Call_TagResource_603569(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
                                        validator: validate_TagResource_603570,
                                        base: "/", url: url_TagResource_603571,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603584 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603586(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603585(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603587 = header.getOrDefault("X-Amz-Date")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Date", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Security-Token")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Security-Token", valid_603588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603589 = header.getOrDefault("X-Amz-Target")
  valid_603589 = validateParameter(valid_603589, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_603589 != nil:
    section.add "X-Amz-Target", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Content-Sha256", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Algorithm")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Algorithm", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Signature")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Signature", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-SignedHeaders", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Credential")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Credential", valid_603594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603596: Call_UntagResource_603584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_603596.validator(path, query, header, formData, body)
  let scheme = call_603596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603596.url(scheme.get, call_603596.host, call_603596.base,
                         call_603596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603596, url, valid)

proc call*(call_603597: Call_UntagResource_603584; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_603598 = newJObject()
  if body != nil:
    body_603598 = body
  result = call_603597.call(nil, nil, nil, nil, body_603598)

var untagResource* = Call_UntagResource_603584(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_603585, base: "/", url: url_UntagResource_603586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_603599 = ref object of OpenApiRestCall_602466
proc url_UpdatePipeline_603601(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePipeline_603600(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603602 = header.getOrDefault("X-Amz-Date")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Date", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Security-Token")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Security-Token", valid_603603
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603604 = header.getOrDefault("X-Amz-Target")
  valid_603604 = validateParameter(valid_603604, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_603604 != nil:
    section.add "X-Amz-Target", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Content-Sha256", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Algorithm")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Algorithm", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Signature")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Signature", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-SignedHeaders", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Credential")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Credential", valid_603609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603611: Call_UpdatePipeline_603599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_603611.validator(path, query, header, formData, body)
  let scheme = call_603611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603611.url(scheme.get, call_603611.host, call_603611.base,
                         call_603611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603611, url, valid)

proc call*(call_603612: Call_UpdatePipeline_603599; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_603613 = newJObject()
  if body != nil:
    body_603613 = body
  result = call_603612.call(nil, nil, nil, nil, body_603613)

var updatePipeline* = Call_UpdatePipeline_603599(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_603600, base: "/", url: url_UpdatePipeline_603601,
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
