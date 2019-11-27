
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AcknowledgeJob_599705 = ref object of OpenApiRestCall_599368
proc url_AcknowledgeJob_599707(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcknowledgeJob_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeJob"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AcknowledgeJob_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AcknowledgeJob_599705; body: JsonNode): Recallable =
  ## acknowledgeJob
  ## Returns information about a specified job and whether that job has been received by the job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var acknowledgeJob* = Call_AcknowledgeJob_599705(name: "acknowledgeJob",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeJob",
    validator: validate_AcknowledgeJob_599706, base: "/", url: url_AcknowledgeJob_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AcknowledgeThirdPartyJob_599974 = ref object of OpenApiRestCall_599368
proc url_AcknowledgeThirdPartyJob_599976(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcknowledgeThirdPartyJob_599975(path: JsonNode; query: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "CodePipeline_20150709.AcknowledgeThirdPartyJob"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_AcknowledgeThirdPartyJob_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_AcknowledgeThirdPartyJob_599974; body: JsonNode): Recallable =
  ## acknowledgeThirdPartyJob
  ## Confirms a job worker has received the specified job. Used for partner actions only.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var acknowledgeThirdPartyJob* = Call_AcknowledgeThirdPartyJob_599974(
    name: "acknowledgeThirdPartyJob", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.AcknowledgeThirdPartyJob",
    validator: validate_AcknowledgeThirdPartyJob_599975, base: "/",
    url: url_AcknowledgeThirdPartyJob_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomActionType_599989 = ref object of OpenApiRestCall_599368
proc url_CreateCustomActionType_599991(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCustomActionType_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreateCustomActionType"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreateCustomActionType_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateCustomActionType_599989; body: JsonNode): Recallable =
  ## createCustomActionType
  ## Creates a new custom action that can be used in all pipelines associated with the AWS account. Only used for custom actions.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createCustomActionType* = Call_CreateCustomActionType_599989(
    name: "createCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreateCustomActionType",
    validator: validate_CreateCustomActionType_599990, base: "/",
    url: url_CreateCustomActionType_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_600004 = ref object of OpenApiRestCall_599368
proc url_CreatePipeline_600006(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "CodePipeline_20150709.CreatePipeline"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_CreatePipeline_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreatePipeline_600004; body: JsonNode): Recallable =
  ## createPipeline
  ## <p>Creates a pipeline.</p> <note> <p>In the pipeline structure, you must include either <code>artifactStore</code> or <code>artifactStores</code> in your pipeline, but you cannot use both. If you create a cross-region action in your pipeline, you must use <code>artifactStores</code>.</p> </note>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createPipeline* = Call_CreatePipeline_600004(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.CreatePipeline",
    validator: validate_CreatePipeline_600005, base: "/", url: url_CreatePipeline_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomActionType_600019 = ref object of OpenApiRestCall_599368
proc url_DeleteCustomActionType_600021(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCustomActionType_600020(path: JsonNode; query: JsonNode;
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteCustomActionType"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeleteCustomActionType_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeleteCustomActionType_600019; body: JsonNode): Recallable =
  ## deleteCustomActionType
  ## <p>Marks a custom action as deleted. <code>PollForJobs</code> for the custom action fails after the action is marked for deletion. Used for custom actions only.</p> <important> <p>To re-create a custom action after it has been deleted you must use a string in the version field that has never been used before. This string can be an incremented version number, for example. To restore a deleted custom action, use a JSON file that is identical to the deleted action, including the original string in the version field.</p> </important>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deleteCustomActionType* = Call_DeleteCustomActionType_600019(
    name: "deleteCustomActionType", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteCustomActionType",
    validator: validate_DeleteCustomActionType_600020, base: "/",
    url: url_DeleteCustomActionType_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_600034 = ref object of OpenApiRestCall_599368
proc url_DeletePipeline_600036(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePipeline_600035(path: JsonNode; query: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeletePipeline"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DeletePipeline_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DeletePipeline_600034; body: JsonNode): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var deletePipeline* = Call_DeletePipeline_600034(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeletePipeline",
    validator: validate_DeletePipeline_600035, base: "/", url: url_DeletePipeline_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_600049 = ref object of OpenApiRestCall_599368
proc url_DeleteWebhook_600051(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWebhook_600050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeleteWebhook"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DeleteWebhook_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DeleteWebhook_600049; body: JsonNode): Recallable =
  ## deleteWebhook
  ## Deletes a previously created webhook by name. Deleting the webhook stops AWS CodePipeline from starting a pipeline every time an external event occurs. The API returns successfully when trying to delete a webhook that is already deleted. If a deleted webhook is re-created by calling PutWebhook with the same name, it will have a different URL.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var deleteWebhook* = Call_DeleteWebhook_600049(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DeleteWebhook",
    validator: validate_DeleteWebhook_600050, base: "/", url: url_DeleteWebhook_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWebhookWithThirdParty_600064 = ref object of OpenApiRestCall_599368
proc url_DeregisterWebhookWithThirdParty_600066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterWebhookWithThirdParty_600065(path: JsonNode;
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "CodePipeline_20150709.DeregisterWebhookWithThirdParty"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DeregisterWebhookWithThirdParty_600064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DeregisterWebhookWithThirdParty_600064; body: JsonNode): Recallable =
  ## deregisterWebhookWithThirdParty
  ## Removes the connection between the webhook that was created by CodePipeline and the external tool with events to be detected. Currently supported only for webhooks that target an action type of GitHub.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var deregisterWebhookWithThirdParty* = Call_DeregisterWebhookWithThirdParty_600064(
    name: "deregisterWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.DeregisterWebhookWithThirdParty",
    validator: validate_DeregisterWebhookWithThirdParty_600065, base: "/",
    url: url_DeregisterWebhookWithThirdParty_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableStageTransition_600079 = ref object of OpenApiRestCall_599368
proc url_DisableStageTransition_600081(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableStageTransition_600080(path: JsonNode; query: JsonNode;
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "CodePipeline_20150709.DisableStageTransition"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_DisableStageTransition_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DisableStageTransition_600079; body: JsonNode): Recallable =
  ## disableStageTransition
  ## Prevents artifacts in a pipeline from transitioning to the next stage in the pipeline.
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var disableStageTransition* = Call_DisableStageTransition_600079(
    name: "disableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.DisableStageTransition",
    validator: validate_DisableStageTransition_600080, base: "/",
    url: url_DisableStageTransition_600081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableStageTransition_600094 = ref object of OpenApiRestCall_599368
proc url_EnableStageTransition_600096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableStageTransition_600095(path: JsonNode; query: JsonNode;
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "CodePipeline_20150709.EnableStageTransition"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_EnableStageTransition_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_EnableStageTransition_600094; body: JsonNode): Recallable =
  ## enableStageTransition
  ## Enables artifacts in a pipeline to transition to a stage in a pipeline.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var enableStageTransition* = Call_EnableStageTransition_600094(
    name: "enableStageTransition", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.EnableStageTransition",
    validator: validate_EnableStageTransition_600095, base: "/",
    url: url_EnableStageTransition_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobDetails_600109 = ref object of OpenApiRestCall_599368
proc url_GetJobDetails_600111(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobDetails_600110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetJobDetails"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_GetJobDetails_600109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_GetJobDetails_600109; body: JsonNode): Recallable =
  ## getJobDetails
  ## <p>Returns information about a job. Used for custom actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var getJobDetails* = Call_GetJobDetails_600109(name: "getJobDetails",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetJobDetails",
    validator: validate_GetJobDetails_600110, base: "/", url: url_GetJobDetails_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipeline_600124 = ref object of OpenApiRestCall_599368
proc url_GetPipeline_600126(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipeline_600125(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipeline"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_GetPipeline_600124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_GetPipeline_600124; body: JsonNode): Recallable =
  ## getPipeline
  ## Returns the metadata, structure, stages, and actions of a pipeline. Can be used to return the entire structure of a pipeline in JSON format, which can then be modified and used to update the pipeline structure with <a>UpdatePipeline</a>.
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var getPipeline* = Call_GetPipeline_600124(name: "getPipeline",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.GetPipeline",
                                        validator: validate_GetPipeline_600125,
                                        base: "/", url: url_GetPipeline_600126,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineExecution_600139 = ref object of OpenApiRestCall_599368
proc url_GetPipelineExecution_600141(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipelineExecution_600140(path: JsonNode; query: JsonNode;
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineExecution"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_GetPipelineExecution_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_GetPipelineExecution_600139; body: JsonNode): Recallable =
  ## getPipelineExecution
  ## Returns information about an execution of a pipeline, including details about artifacts, the pipeline execution ID, and the name, version, and status of the pipeline.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var getPipelineExecution* = Call_GetPipelineExecution_600139(
    name: "getPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineExecution",
    validator: validate_GetPipelineExecution_600140, base: "/",
    url: url_GetPipelineExecution_600141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineState_600154 = ref object of OpenApiRestCall_599368
proc url_GetPipelineState_600156(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPipelineState_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetPipelineState"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_GetPipelineState_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_GetPipelineState_600154; body: JsonNode): Recallable =
  ## getPipelineState
  ## <p>Returns information about the state of a pipeline, including the stages and actions.</p> <note> <p>Values returned in the <code>revisionId</code> and <code>revisionUrl</code> fields indicate the source revision information, such as the commit ID, for the current state.</p> </note>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var getPipelineState* = Call_GetPipelineState_600154(name: "getPipelineState",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetPipelineState",
    validator: validate_GetPipelineState_600155, base: "/",
    url: url_GetPipelineState_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThirdPartyJobDetails_600169 = ref object of OpenApiRestCall_599368
proc url_GetThirdPartyJobDetails_600171(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetThirdPartyJobDetails_600170(path: JsonNode; query: JsonNode;
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "CodePipeline_20150709.GetThirdPartyJobDetails"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_GetThirdPartyJobDetails_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_GetThirdPartyJobDetails_600169; body: JsonNode): Recallable =
  ## getThirdPartyJobDetails
  ## <p>Requests the details of a job for a third party action. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var getThirdPartyJobDetails* = Call_GetThirdPartyJobDetails_600169(
    name: "getThirdPartyJobDetails", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.GetThirdPartyJobDetails",
    validator: validate_GetThirdPartyJobDetails_600170, base: "/",
    url: url_GetThirdPartyJobDetails_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionExecutions_600184 = ref object of OpenApiRestCall_599368
proc url_ListActionExecutions_600186(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActionExecutions_600185(path: JsonNode; query: JsonNode;
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
  var valid_600187 = query.getOrDefault("maxResults")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "maxResults", valid_600187
  var valid_600188 = query.getOrDefault("nextToken")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "nextToken", valid_600188
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
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600191 = header.getOrDefault("X-Amz-Target")
  valid_600191 = validateParameter(valid_600191, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionExecutions"))
  if valid_600191 != nil:
    section.add "X-Amz-Target", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_ListActionExecutions_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the action executions that have occurred in a pipeline.
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_ListActionExecutions_600184; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActionExecutions
  ## Lists the action executions that have occurred in a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600200 = newJObject()
  var body_600201 = newJObject()
  add(query_600200, "maxResults", newJString(maxResults))
  add(query_600200, "nextToken", newJString(nextToken))
  if body != nil:
    body_600201 = body
  result = call_600199.call(nil, query_600200, nil, nil, body_600201)

var listActionExecutions* = Call_ListActionExecutions_600184(
    name: "listActionExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionExecutions",
    validator: validate_ListActionExecutions_600185, base: "/",
    url: url_ListActionExecutions_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActionTypes_600203 = ref object of OpenApiRestCall_599368
proc url_ListActionTypes_600205(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActionTypes_600204(path: JsonNode; query: JsonNode;
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
  var valid_600206 = query.getOrDefault("nextToken")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "nextToken", valid_600206
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
  var valid_600207 = header.getOrDefault("X-Amz-Date")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Date", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Security-Token")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Security-Token", valid_600208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600209 = header.getOrDefault("X-Amz-Target")
  valid_600209 = validateParameter(valid_600209, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListActionTypes"))
  if valid_600209 != nil:
    section.add "X-Amz-Target", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Content-Sha256", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Algorithm")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Algorithm", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Signature")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Signature", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-SignedHeaders", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Credential")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Credential", valid_600214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600216: Call_ListActionTypes_600203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ## 
  let valid = call_600216.validator(path, query, header, formData, body)
  let scheme = call_600216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600216.url(scheme.get, call_600216.host, call_600216.base,
                         call_600216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600216, url, valid)

proc call*(call_600217: Call_ListActionTypes_600203; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listActionTypes
  ## Gets a summary of all AWS CodePipeline action types associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600218 = newJObject()
  var body_600219 = newJObject()
  add(query_600218, "nextToken", newJString(nextToken))
  if body != nil:
    body_600219 = body
  result = call_600217.call(nil, query_600218, nil, nil, body_600219)

var listActionTypes* = Call_ListActionTypes_600203(name: "listActionTypes",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListActionTypes",
    validator: validate_ListActionTypes_600204, base: "/", url: url_ListActionTypes_600205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelineExecutions_600220 = ref object of OpenApiRestCall_599368
proc url_ListPipelineExecutions_600222(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelineExecutions_600221(path: JsonNode; query: JsonNode;
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
  var valid_600223 = query.getOrDefault("maxResults")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "maxResults", valid_600223
  var valid_600224 = query.getOrDefault("nextToken")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "nextToken", valid_600224
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
  var valid_600225 = header.getOrDefault("X-Amz-Date")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Date", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Security-Token")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Security-Token", valid_600226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600227 = header.getOrDefault("X-Amz-Target")
  valid_600227 = validateParameter(valid_600227, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelineExecutions"))
  if valid_600227 != nil:
    section.add "X-Amz-Target", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Content-Sha256", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Algorithm")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Algorithm", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Signature")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Signature", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-SignedHeaders", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Credential")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Credential", valid_600232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600234: Call_ListPipelineExecutions_600220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of the most recent executions for a pipeline.
  ## 
  let valid = call_600234.validator(path, query, header, formData, body)
  let scheme = call_600234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600234.url(scheme.get, call_600234.host, call_600234.base,
                         call_600234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600234, url, valid)

proc call*(call_600235: Call_ListPipelineExecutions_600220; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPipelineExecutions
  ## Gets a summary of the most recent executions for a pipeline.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600236 = newJObject()
  var body_600237 = newJObject()
  add(query_600236, "maxResults", newJString(maxResults))
  add(query_600236, "nextToken", newJString(nextToken))
  if body != nil:
    body_600237 = body
  result = call_600235.call(nil, query_600236, nil, nil, body_600237)

var listPipelineExecutions* = Call_ListPipelineExecutions_600220(
    name: "listPipelineExecutions", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelineExecutions",
    validator: validate_ListPipelineExecutions_600221, base: "/",
    url: url_ListPipelineExecutions_600222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_600238 = ref object of OpenApiRestCall_599368
proc url_ListPipelines_600240(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_600239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600241 = query.getOrDefault("nextToken")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "nextToken", valid_600241
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
  var valid_600242 = header.getOrDefault("X-Amz-Date")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Date", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Security-Token")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Security-Token", valid_600243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600244 = header.getOrDefault("X-Amz-Target")
  valid_600244 = validateParameter(valid_600244, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListPipelines"))
  if valid_600244 != nil:
    section.add "X-Amz-Target", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Content-Sha256", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Algorithm")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Algorithm", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Signature")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Signature", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-SignedHeaders", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Credential")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Credential", valid_600249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600251: Call_ListPipelines_600238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a summary of all of the pipelines associated with your account.
  ## 
  let valid = call_600251.validator(path, query, header, formData, body)
  let scheme = call_600251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600251.url(scheme.get, call_600251.host, call_600251.base,
                         call_600251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600251, url, valid)

proc call*(call_600252: Call_ListPipelines_600238; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Gets a summary of all of the pipelines associated with your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600253 = newJObject()
  var body_600254 = newJObject()
  add(query_600253, "nextToken", newJString(nextToken))
  if body != nil:
    body_600254 = body
  result = call_600252.call(nil, query_600253, nil, nil, body_600254)

var listPipelines* = Call_ListPipelines_600238(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListPipelines",
    validator: validate_ListPipelines_600239, base: "/", url: url_ListPipelines_600240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600255 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600257(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600256(path: JsonNode; query: JsonNode;
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
  var valid_600258 = query.getOrDefault("maxResults")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "maxResults", valid_600258
  var valid_600259 = query.getOrDefault("nextToken")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "nextToken", valid_600259
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
  var valid_600260 = header.getOrDefault("X-Amz-Date")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Date", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Security-Token")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Security-Token", valid_600261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600262 = header.getOrDefault("X-Amz-Target")
  valid_600262 = validateParameter(valid_600262, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListTagsForResource"))
  if valid_600262 != nil:
    section.add "X-Amz-Target", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_ListTagsForResource_600255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_ListTagsForResource_600255; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Gets the set of key-value pairs (metadata) that are used to manage the resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600271 = newJObject()
  var body_600272 = newJObject()
  add(query_600271, "maxResults", newJString(maxResults))
  add(query_600271, "nextToken", newJString(nextToken))
  if body != nil:
    body_600272 = body
  result = call_600270.call(nil, query_600271, nil, nil, body_600272)

var listTagsForResource* = Call_ListTagsForResource_600255(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListTagsForResource",
    validator: validate_ListTagsForResource_600256, base: "/",
    url: url_ListTagsForResource_600257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_600273 = ref object of OpenApiRestCall_599368
proc url_ListWebhooks_600275(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebhooks_600274(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600276 = query.getOrDefault("NextToken")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "NextToken", valid_600276
  var valid_600277 = query.getOrDefault("MaxResults")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "MaxResults", valid_600277
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
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600280 = header.getOrDefault("X-Amz-Target")
  valid_600280 = validateParameter(valid_600280, JString, required = true, default = newJString(
      "CodePipeline_20150709.ListWebhooks"))
  if valid_600280 != nil:
    section.add "X-Amz-Target", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Content-Sha256", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Algorithm")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Algorithm", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Signature")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Signature", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-SignedHeaders", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Credential")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Credential", valid_600285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600287: Call_ListWebhooks_600273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_ListWebhooks_600273; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebhooks
  ## Gets a listing of all the webhooks in this AWS Region for this account. The output lists all webhooks and includes the webhook URL and ARN and the configuration for each webhook.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600289 = newJObject()
  var body_600290 = newJObject()
  add(query_600289, "NextToken", newJString(NextToken))
  if body != nil:
    body_600290 = body
  add(query_600289, "MaxResults", newJString(MaxResults))
  result = call_600288.call(nil, query_600289, nil, nil, body_600290)

var listWebhooks* = Call_ListWebhooks_600273(name: "listWebhooks",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.ListWebhooks",
    validator: validate_ListWebhooks_600274, base: "/", url: url_ListWebhooks_600275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForJobs_600291 = ref object of OpenApiRestCall_599368
proc url_PollForJobs_600293(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PollForJobs_600292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600294 = header.getOrDefault("X-Amz-Date")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Date", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Security-Token")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Security-Token", valid_600295
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600296 = header.getOrDefault("X-Amz-Target")
  valid_600296 = validateParameter(valid_600296, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForJobs"))
  if valid_600296 != nil:
    section.add "X-Amz-Target", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Content-Sha256", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Algorithm")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Algorithm", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Signature")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Signature", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-SignedHeaders", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Credential")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Credential", valid_600301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600303: Call_PollForJobs_600291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ## 
  let valid = call_600303.validator(path, query, header, formData, body)
  let scheme = call_600303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600303.url(scheme.get, call_600303.host, call_600303.base,
                         call_600303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600303, url, valid)

proc call*(call_600304: Call_PollForJobs_600291; body: JsonNode): Recallable =
  ## pollForJobs
  ## <p>Returns information about any jobs for AWS CodePipeline to act on. <code>PollForJobs</code> is valid only for action types with "Custom" in the owner field. If the action type contains "AWS" or "ThirdParty" in the owner field, the <code>PollForJobs</code> action returns an error.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts. This API also returns any secret values defined for the action.</p> </important>
  ##   body: JObject (required)
  var body_600305 = newJObject()
  if body != nil:
    body_600305 = body
  result = call_600304.call(nil, nil, nil, nil, body_600305)

var pollForJobs* = Call_PollForJobs_600291(name: "pollForJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PollForJobs",
                                        validator: validate_PollForJobs_600292,
                                        base: "/", url: url_PollForJobs_600293,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForThirdPartyJobs_600306 = ref object of OpenApiRestCall_599368
proc url_PollForThirdPartyJobs_600308(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PollForThirdPartyJobs_600307(path: JsonNode; query: JsonNode;
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
  var valid_600309 = header.getOrDefault("X-Amz-Date")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Date", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Security-Token")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Security-Token", valid_600310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600311 = header.getOrDefault("X-Amz-Target")
  valid_600311 = validateParameter(valid_600311, JString, required = true, default = newJString(
      "CodePipeline_20150709.PollForThirdPartyJobs"))
  if valid_600311 != nil:
    section.add "X-Amz-Target", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Content-Sha256", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Algorithm")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Algorithm", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Signature")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Signature", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-SignedHeaders", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Credential")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Credential", valid_600316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600318: Call_PollForThirdPartyJobs_600306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ## 
  let valid = call_600318.validator(path, query, header, formData, body)
  let scheme = call_600318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600318.url(scheme.get, call_600318.host, call_600318.base,
                         call_600318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600318, url, valid)

proc call*(call_600319: Call_PollForThirdPartyJobs_600306; body: JsonNode): Recallable =
  ## pollForThirdPartyJobs
  ## <p>Determines whether there are any third party jobs for a job worker to act on. Used for partner actions only.</p> <important> <p>When this API is called, AWS CodePipeline returns temporary credentials for the Amazon S3 bucket used to store artifacts for the pipeline, if the action requires access to that Amazon S3 bucket for input or output artifacts.</p> </important>
  ##   body: JObject (required)
  var body_600320 = newJObject()
  if body != nil:
    body_600320 = body
  result = call_600319.call(nil, nil, nil, nil, body_600320)

var pollForThirdPartyJobs* = Call_PollForThirdPartyJobs_600306(
    name: "pollForThirdPartyJobs", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PollForThirdPartyJobs",
    validator: validate_PollForThirdPartyJobs_600307, base: "/",
    url: url_PollForThirdPartyJobs_600308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutActionRevision_600321 = ref object of OpenApiRestCall_599368
proc url_PutActionRevision_600323(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutActionRevision_600322(path: JsonNode; query: JsonNode;
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
  var valid_600324 = header.getOrDefault("X-Amz-Date")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Date", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Security-Token")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Security-Token", valid_600325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600326 = header.getOrDefault("X-Amz-Target")
  valid_600326 = validateParameter(valid_600326, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutActionRevision"))
  if valid_600326 != nil:
    section.add "X-Amz-Target", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Content-Sha256", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Algorithm")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Algorithm", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Signature")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Signature", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-SignedHeaders", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Credential")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Credential", valid_600331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600333: Call_PutActionRevision_600321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ## 
  let valid = call_600333.validator(path, query, header, formData, body)
  let scheme = call_600333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600333.url(scheme.get, call_600333.host, call_600333.base,
                         call_600333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600333, url, valid)

proc call*(call_600334: Call_PutActionRevision_600321; body: JsonNode): Recallable =
  ## putActionRevision
  ## Provides information to AWS CodePipeline about new revisions to a source.
  ##   body: JObject (required)
  var body_600335 = newJObject()
  if body != nil:
    body_600335 = body
  result = call_600334.call(nil, nil, nil, nil, body_600335)

var putActionRevision* = Call_PutActionRevision_600321(name: "putActionRevision",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutActionRevision",
    validator: validate_PutActionRevision_600322, base: "/",
    url: url_PutActionRevision_600323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutApprovalResult_600336 = ref object of OpenApiRestCall_599368
proc url_PutApprovalResult_600338(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutApprovalResult_600337(path: JsonNode; query: JsonNode;
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
  var valid_600339 = header.getOrDefault("X-Amz-Date")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Date", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Security-Token")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Security-Token", valid_600340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600341 = header.getOrDefault("X-Amz-Target")
  valid_600341 = validateParameter(valid_600341, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutApprovalResult"))
  if valid_600341 != nil:
    section.add "X-Amz-Target", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Content-Sha256", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Algorithm")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Algorithm", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Signature")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Signature", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-SignedHeaders", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Credential")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Credential", valid_600346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600348: Call_PutApprovalResult_600336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ## 
  let valid = call_600348.validator(path, query, header, formData, body)
  let scheme = call_600348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600348.url(scheme.get, call_600348.host, call_600348.base,
                         call_600348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600348, url, valid)

proc call*(call_600349: Call_PutApprovalResult_600336; body: JsonNode): Recallable =
  ## putApprovalResult
  ## Provides the response to a manual approval request to AWS CodePipeline. Valid responses include Approved and Rejected.
  ##   body: JObject (required)
  var body_600350 = newJObject()
  if body != nil:
    body_600350 = body
  result = call_600349.call(nil, nil, nil, nil, body_600350)

var putApprovalResult* = Call_PutApprovalResult_600336(name: "putApprovalResult",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutApprovalResult",
    validator: validate_PutApprovalResult_600337, base: "/",
    url: url_PutApprovalResult_600338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobFailureResult_600351 = ref object of OpenApiRestCall_599368
proc url_PutJobFailureResult_600353(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutJobFailureResult_600352(path: JsonNode; query: JsonNode;
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
  var valid_600354 = header.getOrDefault("X-Amz-Date")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Date", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Security-Token")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Security-Token", valid_600355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600356 = header.getOrDefault("X-Amz-Target")
  valid_600356 = validateParameter(valid_600356, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobFailureResult"))
  if valid_600356 != nil:
    section.add "X-Amz-Target", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Content-Sha256", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Algorithm")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Algorithm", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Signature")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Signature", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-SignedHeaders", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Credential")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Credential", valid_600361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600363: Call_PutJobFailureResult_600351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_600363.validator(path, query, header, formData, body)
  let scheme = call_600363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600363.url(scheme.get, call_600363.host, call_600363.base,
                         call_600363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600363, url, valid)

proc call*(call_600364: Call_PutJobFailureResult_600351; body: JsonNode): Recallable =
  ## putJobFailureResult
  ## Represents the failure of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_600365 = newJObject()
  if body != nil:
    body_600365 = body
  result = call_600364.call(nil, nil, nil, nil, body_600365)

var putJobFailureResult* = Call_PutJobFailureResult_600351(
    name: "putJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobFailureResult",
    validator: validate_PutJobFailureResult_600352, base: "/",
    url: url_PutJobFailureResult_600353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutJobSuccessResult_600366 = ref object of OpenApiRestCall_599368
proc url_PutJobSuccessResult_600368(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutJobSuccessResult_600367(path: JsonNode; query: JsonNode;
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
  var valid_600369 = header.getOrDefault("X-Amz-Date")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Date", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Security-Token")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Security-Token", valid_600370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600371 = header.getOrDefault("X-Amz-Target")
  valid_600371 = validateParameter(valid_600371, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutJobSuccessResult"))
  if valid_600371 != nil:
    section.add "X-Amz-Target", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Content-Sha256", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Algorithm")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Algorithm", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Signature")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Signature", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-SignedHeaders", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Credential")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Credential", valid_600376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600378: Call_PutJobSuccessResult_600366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ## 
  let valid = call_600378.validator(path, query, header, formData, body)
  let scheme = call_600378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600378.url(scheme.get, call_600378.host, call_600378.base,
                         call_600378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600378, url, valid)

proc call*(call_600379: Call_PutJobSuccessResult_600366; body: JsonNode): Recallable =
  ## putJobSuccessResult
  ## Represents the success of a job as returned to the pipeline by a job worker. Used for custom actions only.
  ##   body: JObject (required)
  var body_600380 = newJObject()
  if body != nil:
    body_600380 = body
  result = call_600379.call(nil, nil, nil, nil, body_600380)

var putJobSuccessResult* = Call_PutJobSuccessResult_600366(
    name: "putJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.PutJobSuccessResult",
    validator: validate_PutJobSuccessResult_600367, base: "/",
    url: url_PutJobSuccessResult_600368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobFailureResult_600381 = ref object of OpenApiRestCall_599368
proc url_PutThirdPartyJobFailureResult_600383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutThirdPartyJobFailureResult_600382(path: JsonNode; query: JsonNode;
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
  var valid_600384 = header.getOrDefault("X-Amz-Date")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Date", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Security-Token")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Security-Token", valid_600385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600386 = header.getOrDefault("X-Amz-Target")
  valid_600386 = validateParameter(valid_600386, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobFailureResult"))
  if valid_600386 != nil:
    section.add "X-Amz-Target", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Content-Sha256", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Algorithm")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Algorithm", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Signature")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Signature", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-SignedHeaders", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Credential")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Credential", valid_600391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600393: Call_PutThirdPartyJobFailureResult_600381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_600393.validator(path, query, header, formData, body)
  let scheme = call_600393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600393.url(scheme.get, call_600393.host, call_600393.base,
                         call_600393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600393, url, valid)

proc call*(call_600394: Call_PutThirdPartyJobFailureResult_600381; body: JsonNode): Recallable =
  ## putThirdPartyJobFailureResult
  ## Represents the failure of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_600395 = newJObject()
  if body != nil:
    body_600395 = body
  result = call_600394.call(nil, nil, nil, nil, body_600395)

var putThirdPartyJobFailureResult* = Call_PutThirdPartyJobFailureResult_600381(
    name: "putThirdPartyJobFailureResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobFailureResult",
    validator: validate_PutThirdPartyJobFailureResult_600382, base: "/",
    url: url_PutThirdPartyJobFailureResult_600383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutThirdPartyJobSuccessResult_600396 = ref object of OpenApiRestCall_599368
proc url_PutThirdPartyJobSuccessResult_600398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutThirdPartyJobSuccessResult_600397(path: JsonNode; query: JsonNode;
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
  var valid_600399 = header.getOrDefault("X-Amz-Date")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Date", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Security-Token")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Security-Token", valid_600400
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600401 = header.getOrDefault("X-Amz-Target")
  valid_600401 = validateParameter(valid_600401, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutThirdPartyJobSuccessResult"))
  if valid_600401 != nil:
    section.add "X-Amz-Target", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Content-Sha256", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Algorithm")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Algorithm", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Signature")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Signature", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-SignedHeaders", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Credential")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Credential", valid_600406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600408: Call_PutThirdPartyJobSuccessResult_600396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ## 
  let valid = call_600408.validator(path, query, header, formData, body)
  let scheme = call_600408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600408.url(scheme.get, call_600408.host, call_600408.base,
                         call_600408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600408, url, valid)

proc call*(call_600409: Call_PutThirdPartyJobSuccessResult_600396; body: JsonNode): Recallable =
  ## putThirdPartyJobSuccessResult
  ## Represents the success of a third party job as returned to the pipeline by a job worker. Used for partner actions only.
  ##   body: JObject (required)
  var body_600410 = newJObject()
  if body != nil:
    body_600410 = body
  result = call_600409.call(nil, nil, nil, nil, body_600410)

var putThirdPartyJobSuccessResult* = Call_PutThirdPartyJobSuccessResult_600396(
    name: "putThirdPartyJobSuccessResult", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutThirdPartyJobSuccessResult",
    validator: validate_PutThirdPartyJobSuccessResult_600397, base: "/",
    url: url_PutThirdPartyJobSuccessResult_600398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWebhook_600411 = ref object of OpenApiRestCall_599368
proc url_PutWebhook_600413(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWebhook_600412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600414 = header.getOrDefault("X-Amz-Date")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Date", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Security-Token")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Security-Token", valid_600415
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600416 = header.getOrDefault("X-Amz-Target")
  valid_600416 = validateParameter(valid_600416, JString, required = true, default = newJString(
      "CodePipeline_20150709.PutWebhook"))
  if valid_600416 != nil:
    section.add "X-Amz-Target", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Content-Sha256", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Algorithm")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Algorithm", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Signature")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Signature", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-SignedHeaders", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Credential")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Credential", valid_600421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600423: Call_PutWebhook_600411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ## 
  let valid = call_600423.validator(path, query, header, formData, body)
  let scheme = call_600423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600423.url(scheme.get, call_600423.host, call_600423.base,
                         call_600423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600423, url, valid)

proc call*(call_600424: Call_PutWebhook_600411; body: JsonNode): Recallable =
  ## putWebhook
  ## Defines a webhook and returns a unique webhook URL generated by CodePipeline. This URL can be supplied to third party source hosting providers to call every time there's a code change. When CodePipeline receives a POST request on this URL, the pipeline defined in the webhook is started as long as the POST request satisfied the authentication and filtering requirements supplied when defining the webhook. RegisterWebhookWithThirdParty and DeregisterWebhookWithThirdParty APIs can be used to automatically configure supported third parties to call the generated webhook URL.
  ##   body: JObject (required)
  var body_600425 = newJObject()
  if body != nil:
    body_600425 = body
  result = call_600424.call(nil, nil, nil, nil, body_600425)

var putWebhook* = Call_PutWebhook_600411(name: "putWebhook",
                                      meth: HttpMethod.HttpPost,
                                      host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.PutWebhook",
                                      validator: validate_PutWebhook_600412,
                                      base: "/", url: url_PutWebhook_600413,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWebhookWithThirdParty_600426 = ref object of OpenApiRestCall_599368
proc url_RegisterWebhookWithThirdParty_600428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterWebhookWithThirdParty_600427(path: JsonNode; query: JsonNode;
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
  var valid_600429 = header.getOrDefault("X-Amz-Date")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Date", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Security-Token")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Security-Token", valid_600430
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600431 = header.getOrDefault("X-Amz-Target")
  valid_600431 = validateParameter(valid_600431, JString, required = true, default = newJString(
      "CodePipeline_20150709.RegisterWebhookWithThirdParty"))
  if valid_600431 != nil:
    section.add "X-Amz-Target", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Content-Sha256", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Algorithm")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Algorithm", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Signature")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Signature", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-SignedHeaders", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Credential")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Credential", valid_600436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600438: Call_RegisterWebhookWithThirdParty_600426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ## 
  let valid = call_600438.validator(path, query, header, formData, body)
  let scheme = call_600438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600438.url(scheme.get, call_600438.host, call_600438.base,
                         call_600438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600438, url, valid)

proc call*(call_600439: Call_RegisterWebhookWithThirdParty_600426; body: JsonNode): Recallable =
  ## registerWebhookWithThirdParty
  ## Configures a connection between the webhook that was created and the external tool with events to be detected.
  ##   body: JObject (required)
  var body_600440 = newJObject()
  if body != nil:
    body_600440 = body
  result = call_600439.call(nil, nil, nil, nil, body_600440)

var registerWebhookWithThirdParty* = Call_RegisterWebhookWithThirdParty_600426(
    name: "registerWebhookWithThirdParty", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.RegisterWebhookWithThirdParty",
    validator: validate_RegisterWebhookWithThirdParty_600427, base: "/",
    url: url_RegisterWebhookWithThirdParty_600428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetryStageExecution_600441 = ref object of OpenApiRestCall_599368
proc url_RetryStageExecution_600443(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetryStageExecution_600442(path: JsonNode; query: JsonNode;
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
  var valid_600444 = header.getOrDefault("X-Amz-Date")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Date", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Security-Token")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Security-Token", valid_600445
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600446 = header.getOrDefault("X-Amz-Target")
  valid_600446 = validateParameter(valid_600446, JString, required = true, default = newJString(
      "CodePipeline_20150709.RetryStageExecution"))
  if valid_600446 != nil:
    section.add "X-Amz-Target", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Content-Sha256", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Algorithm")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Algorithm", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Signature")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Signature", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-SignedHeaders", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Credential")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Credential", valid_600451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600453: Call_RetryStageExecution_600441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ## 
  let valid = call_600453.validator(path, query, header, formData, body)
  let scheme = call_600453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600453.url(scheme.get, call_600453.host, call_600453.base,
                         call_600453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600453, url, valid)

proc call*(call_600454: Call_RetryStageExecution_600441; body: JsonNode): Recallable =
  ## retryStageExecution
  ## Resumes the pipeline execution by retrying the last failed actions in a stage. You can retry a stage immediately if any of the actions in the stage fail. When you retry, all actions that are still in progress continue working, and failed actions are triggered again.
  ##   body: JObject (required)
  var body_600455 = newJObject()
  if body != nil:
    body_600455 = body
  result = call_600454.call(nil, nil, nil, nil, body_600455)

var retryStageExecution* = Call_RetryStageExecution_600441(
    name: "retryStageExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.RetryStageExecution",
    validator: validate_RetryStageExecution_600442, base: "/",
    url: url_RetryStageExecution_600443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineExecution_600456 = ref object of OpenApiRestCall_599368
proc url_StartPipelineExecution_600458(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartPipelineExecution_600457(path: JsonNode; query: JsonNode;
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
  var valid_600459 = header.getOrDefault("X-Amz-Date")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Date", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Security-Token")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Security-Token", valid_600460
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600461 = header.getOrDefault("X-Amz-Target")
  valid_600461 = validateParameter(valid_600461, JString, required = true, default = newJString(
      "CodePipeline_20150709.StartPipelineExecution"))
  if valid_600461 != nil:
    section.add "X-Amz-Target", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Content-Sha256", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Algorithm")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Algorithm", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Signature")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Signature", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-SignedHeaders", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Credential")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Credential", valid_600466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600468: Call_StartPipelineExecution_600456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ## 
  let valid = call_600468.validator(path, query, header, formData, body)
  let scheme = call_600468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600468.url(scheme.get, call_600468.host, call_600468.base,
                         call_600468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600468, url, valid)

proc call*(call_600469: Call_StartPipelineExecution_600456; body: JsonNode): Recallable =
  ## startPipelineExecution
  ## Starts the specified pipeline. Specifically, it begins processing the latest commit to the source location specified as part of the pipeline.
  ##   body: JObject (required)
  var body_600470 = newJObject()
  if body != nil:
    body_600470 = body
  result = call_600469.call(nil, nil, nil, nil, body_600470)

var startPipelineExecution* = Call_StartPipelineExecution_600456(
    name: "startPipelineExecution", meth: HttpMethod.HttpPost,
    host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.StartPipelineExecution",
    validator: validate_StartPipelineExecution_600457, base: "/",
    url: url_StartPipelineExecution_600458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600471 = ref object of OpenApiRestCall_599368
proc url_TagResource_600473(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600472(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600474 = header.getOrDefault("X-Amz-Date")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Date", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Security-Token")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Security-Token", valid_600475
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600476 = header.getOrDefault("X-Amz-Target")
  valid_600476 = validateParameter(valid_600476, JString, required = true, default = newJString(
      "CodePipeline_20150709.TagResource"))
  if valid_600476 != nil:
    section.add "X-Amz-Target", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Content-Sha256", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Algorithm")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Algorithm", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Signature")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Signature", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-SignedHeaders", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Credential")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Credential", valid_600481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600483: Call_TagResource_600471; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ## 
  let valid = call_600483.validator(path, query, header, formData, body)
  let scheme = call_600483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600483.url(scheme.get, call_600483.host, call_600483.base,
                         call_600483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600483, url, valid)

proc call*(call_600484: Call_TagResource_600471; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource. 
  ##   body: JObject (required)
  var body_600485 = newJObject()
  if body != nil:
    body_600485 = body
  result = call_600484.call(nil, nil, nil, nil, body_600485)

var tagResource* = Call_TagResource_600471(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codepipeline.amazonaws.com", route: "/#X-Amz-Target=CodePipeline_20150709.TagResource",
                                        validator: validate_TagResource_600472,
                                        base: "/", url: url_TagResource_600473,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600486 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600488(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600489 = header.getOrDefault("X-Amz-Date")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Date", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Security-Token")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Security-Token", valid_600490
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600491 = header.getOrDefault("X-Amz-Target")
  valid_600491 = validateParameter(valid_600491, JString, required = true, default = newJString(
      "CodePipeline_20150709.UntagResource"))
  if valid_600491 != nil:
    section.add "X-Amz-Target", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Content-Sha256", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Algorithm")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Algorithm", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Signature")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Signature", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-SignedHeaders", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-Credential")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Credential", valid_600496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600498: Call_UntagResource_600486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS resource.
  ## 
  let valid = call_600498.validator(path, query, header, formData, body)
  let scheme = call_600498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600498.url(scheme.get, call_600498.host, call_600498.base,
                         call_600498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600498, url, valid)

proc call*(call_600499: Call_UntagResource_600486; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS resource.
  ##   body: JObject (required)
  var body_600500 = newJObject()
  if body != nil:
    body_600500 = body
  result = call_600499.call(nil, nil, nil, nil, body_600500)

var untagResource* = Call_UntagResource_600486(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UntagResource",
    validator: validate_UntagResource_600487, base: "/", url: url_UntagResource_600488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_600501 = ref object of OpenApiRestCall_599368
proc url_UpdatePipeline_600503(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePipeline_600502(path: JsonNode; query: JsonNode;
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
  var valid_600504 = header.getOrDefault("X-Amz-Date")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Date", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Security-Token")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Security-Token", valid_600505
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600506 = header.getOrDefault("X-Amz-Target")
  valid_600506 = validateParameter(valid_600506, JString, required = true, default = newJString(
      "CodePipeline_20150709.UpdatePipeline"))
  if valid_600506 != nil:
    section.add "X-Amz-Target", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Content-Sha256", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Algorithm")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Algorithm", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Signature")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Signature", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-SignedHeaders", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Credential")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Credential", valid_600511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600513: Call_UpdatePipeline_600501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ## 
  let valid = call_600513.validator(path, query, header, formData, body)
  let scheme = call_600513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600513.url(scheme.get, call_600513.host, call_600513.base,
                         call_600513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600513, url, valid)

proc call*(call_600514: Call_UpdatePipeline_600501; body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates a specified pipeline with edits or changes to its structure. Use a JSON file with the pipeline structure and <code>UpdatePipeline</code> to provide the full structure of the pipeline. Updating the pipeline increases the version number of the pipeline by 1.
  ##   body: JObject (required)
  var body_600515 = newJObject()
  if body != nil:
    body_600515 = body
  result = call_600514.call(nil, nil, nil, nil, body_600515)

var updatePipeline* = Call_UpdatePipeline_600501(name: "updatePipeline",
    meth: HttpMethod.HttpPost, host: "codepipeline.amazonaws.com",
    route: "/#X-Amz-Target=CodePipeline_20150709.UpdatePipeline",
    validator: validate_UpdatePipeline_600502, base: "/", url: url_UpdatePipeline_600503,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
