
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Data Pipeline
## version: 2012-10-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Data Pipeline configures and manages a data-driven workflow called a pipeline. AWS Data Pipeline handles the details of scheduling and ensuring that data dependencies are met so that your application can focus on processing the data.</p> <p>AWS Data Pipeline provides a JAR implementation of a task runner called AWS Data Pipeline Task Runner. AWS Data Pipeline Task Runner provides logic for common data management scenarios, such as performing database queries and running data analysis using Amazon Elastic MapReduce (Amazon EMR). You can use AWS Data Pipeline Task Runner as your task runner, or you can write your own task runner to provide custom data management.</p> <p>AWS Data Pipeline implements two main sets of functionality. Use the first set to create a pipeline and define data sources, schedules, dependencies, and the transforms to be performed on the data. Use the second set in your task runner application to receive the next task ready for processing. The logic for performing the task, such as querying the data, running data analysis, or converting the data from one format to another, is contained within the task runner. The task runner performs the task assigned to it by the web service, reporting progress to the web service as it does so. When the task is done, the task runner reports the final success or failure of the task to the web service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/datapipeline/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "datapipeline.ap-northeast-1.amazonaws.com", "ap-southeast-1": "datapipeline.ap-southeast-1.amazonaws.com",
                           "us-west-2": "datapipeline.us-west-2.amazonaws.com",
                           "eu-west-2": "datapipeline.eu-west-2.amazonaws.com", "ap-northeast-3": "datapipeline.ap-northeast-3.amazonaws.com", "eu-central-1": "datapipeline.eu-central-1.amazonaws.com",
                           "us-east-2": "datapipeline.us-east-2.amazonaws.com",
                           "us-east-1": "datapipeline.us-east-1.amazonaws.com", "cn-northwest-1": "datapipeline.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "datapipeline.ap-south-1.amazonaws.com", "eu-north-1": "datapipeline.eu-north-1.amazonaws.com", "ap-northeast-2": "datapipeline.ap-northeast-2.amazonaws.com",
                           "us-west-1": "datapipeline.us-west-1.amazonaws.com", "us-gov-east-1": "datapipeline.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "datapipeline.eu-west-3.amazonaws.com", "cn-north-1": "datapipeline.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "datapipeline.sa-east-1.amazonaws.com",
                           "eu-west-1": "datapipeline.eu-west-1.amazonaws.com", "us-gov-west-1": "datapipeline.us-gov-west-1.amazonaws.com", "ap-southeast-2": "datapipeline.ap-southeast-2.amazonaws.com", "ca-central-1": "datapipeline.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "datapipeline.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "datapipeline.ap-southeast-1.amazonaws.com",
      "us-west-2": "datapipeline.us-west-2.amazonaws.com",
      "eu-west-2": "datapipeline.eu-west-2.amazonaws.com",
      "ap-northeast-3": "datapipeline.ap-northeast-3.amazonaws.com",
      "eu-central-1": "datapipeline.eu-central-1.amazonaws.com",
      "us-east-2": "datapipeline.us-east-2.amazonaws.com",
      "us-east-1": "datapipeline.us-east-1.amazonaws.com",
      "cn-northwest-1": "datapipeline.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "datapipeline.ap-south-1.amazonaws.com",
      "eu-north-1": "datapipeline.eu-north-1.amazonaws.com",
      "ap-northeast-2": "datapipeline.ap-northeast-2.amazonaws.com",
      "us-west-1": "datapipeline.us-west-1.amazonaws.com",
      "us-gov-east-1": "datapipeline.us-gov-east-1.amazonaws.com",
      "eu-west-3": "datapipeline.eu-west-3.amazonaws.com",
      "cn-north-1": "datapipeline.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "datapipeline.sa-east-1.amazonaws.com",
      "eu-west-1": "datapipeline.eu-west-1.amazonaws.com",
      "us-gov-west-1": "datapipeline.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "datapipeline.ap-southeast-2.amazonaws.com",
      "ca-central-1": "datapipeline.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "datapipeline"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ActivatePipeline_602803 = ref object of OpenApiRestCall_602466
proc url_ActivatePipeline_602805(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ActivatePipeline_602804(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
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
      "DataPipeline.ActivatePipeline"))
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

proc call*(call_602961: Call_ActivatePipeline_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_ActivatePipeline_602803; body: JsonNode): Recallable =
  ## activatePipeline
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var activatePipeline* = Call_ActivatePipeline_602803(name: "activatePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ActivatePipeline",
    validator: validate_ActivatePipeline_602804, base: "/",
    url: url_ActivatePipeline_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTags_603072 = ref object of OpenApiRestCall_602466
proc url_AddTags_603074(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTags_603073(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or modifies tags for the specified pipeline.
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
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = newJString("DataPipeline.AddTags"))
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

proc call*(call_603084: Call_AddTags_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or modifies tags for the specified pipeline.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AddTags_603072; body: JsonNode): Recallable =
  ## addTags
  ## Adds or modifies tags for the specified pipeline.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var addTags* = Call_AddTags_603072(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "datapipeline.amazonaws.com",
                                route: "/#X-Amz-Target=DataPipeline.AddTags",
                                validator: validate_AddTags_603073, base: "/",
                                url: url_AddTags_603074,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_603087 = ref object of OpenApiRestCall_602466
proc url_CreatePipeline_603089(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_603088(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
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
      "DataPipeline.CreatePipeline"))
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

proc call*(call_603099: Call_CreatePipeline_603087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreatePipeline_603087; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createPipeline* = Call_CreatePipeline_603087(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.CreatePipeline",
    validator: validate_CreatePipeline_603088, base: "/", url: url_CreatePipeline_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivatePipeline_603102 = ref object of OpenApiRestCall_602466
proc url_DeactivatePipeline_603104(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeactivatePipeline_603103(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
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
      "DataPipeline.DeactivatePipeline"))
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

proc call*(call_603114: Call_DeactivatePipeline_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_DeactivatePipeline_603102; body: JsonNode): Recallable =
  ## deactivatePipeline
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var deactivatePipeline* = Call_DeactivatePipeline_603102(
    name: "deactivatePipeline", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeactivatePipeline",
    validator: validate_DeactivatePipeline_603103, base: "/",
    url: url_DeactivatePipeline_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_603117 = ref object of OpenApiRestCall_602466
proc url_DeletePipeline_603119(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePipeline_603118(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
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
      "DataPipeline.DeletePipeline"))
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

proc call*(call_603129: Call_DeletePipeline_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeletePipeline_603117; body: JsonNode): Recallable =
  ## deletePipeline
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deletePipeline* = Call_DeletePipeline_603117(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeletePipeline",
    validator: validate_DeletePipeline_603118, base: "/", url: url_DeletePipeline_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObjects_603132 = ref object of OpenApiRestCall_602466
proc url_DescribeObjects_603134(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeObjects_603133(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_603135 = query.getOrDefault("marker")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "marker", valid_603135
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
      "DataPipeline.DescribeObjects"))
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

proc call*(call_603145: Call_DescribeObjects_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603145, url, valid)

proc call*(call_603146: Call_DescribeObjects_603132; body: JsonNode;
          marker: string = ""): Recallable =
  ## describeObjects
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603147 = newJObject()
  var body_603148 = newJObject()
  add(query_603147, "marker", newJString(marker))
  if body != nil:
    body_603148 = body
  result = call_603146.call(nil, query_603147, nil, nil, body_603148)

var describeObjects* = Call_DescribeObjects_603132(name: "describeObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribeObjects",
    validator: validate_DescribeObjects_603133, base: "/", url: url_DescribeObjects_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipelines_603150 = ref object of OpenApiRestCall_602466
proc url_DescribePipelines_603152(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePipelines_603151(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
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
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Security-Token")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Security-Token", valid_603154
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603155 = header.getOrDefault("X-Amz-Target")
  valid_603155 = validateParameter(valid_603155, JString, required = true, default = newJString(
      "DataPipeline.DescribePipelines"))
  if valid_603155 != nil:
    section.add "X-Amz-Target", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Signature")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Signature", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-SignedHeaders", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Credential")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Credential", valid_603160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_DescribePipelines_603150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ## 
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603162, url, valid)

proc call*(call_603163: Call_DescribePipelines_603150; body: JsonNode): Recallable =
  ## describePipelines
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ##   body: JObject (required)
  var body_603164 = newJObject()
  if body != nil:
    body_603164 = body
  result = call_603163.call(nil, nil, nil, nil, body_603164)

var describePipelines* = Call_DescribePipelines_603150(name: "describePipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribePipelines",
    validator: validate_DescribePipelines_603151, base: "/",
    url: url_DescribePipelines_603152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluateExpression_603165 = ref object of OpenApiRestCall_602466
proc url_EvaluateExpression_603167(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EvaluateExpression_603166(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
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
  var valid_603168 = header.getOrDefault("X-Amz-Date")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Date", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Security-Token")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Security-Token", valid_603169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603170 = header.getOrDefault("X-Amz-Target")
  valid_603170 = validateParameter(valid_603170, JString, required = true, default = newJString(
      "DataPipeline.EvaluateExpression"))
  if valid_603170 != nil:
    section.add "X-Amz-Target", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Algorithm")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Algorithm", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Signature")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Signature", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Credential")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Credential", valid_603175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603177: Call_EvaluateExpression_603165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ## 
  let valid = call_603177.validator(path, query, header, formData, body)
  let scheme = call_603177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603177.url(scheme.get, call_603177.host, call_603177.base,
                         call_603177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603177, url, valid)

proc call*(call_603178: Call_EvaluateExpression_603165; body: JsonNode): Recallable =
  ## evaluateExpression
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ##   body: JObject (required)
  var body_603179 = newJObject()
  if body != nil:
    body_603179 = body
  result = call_603178.call(nil, nil, nil, nil, body_603179)

var evaluateExpression* = Call_EvaluateExpression_603165(
    name: "evaluateExpression", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.EvaluateExpression",
    validator: validate_EvaluateExpression_603166, base: "/",
    url: url_EvaluateExpression_603167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineDefinition_603180 = ref object of OpenApiRestCall_602466
proc url_GetPipelineDefinition_603182(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPipelineDefinition_603181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
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
  var valid_603183 = header.getOrDefault("X-Amz-Date")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Date", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Security-Token")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Security-Token", valid_603184
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603185 = header.getOrDefault("X-Amz-Target")
  valid_603185 = validateParameter(valid_603185, JString, required = true, default = newJString(
      "DataPipeline.GetPipelineDefinition"))
  if valid_603185 != nil:
    section.add "X-Amz-Target", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_GetPipelineDefinition_603180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ## 
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_GetPipelineDefinition_603180; body: JsonNode): Recallable =
  ## getPipelineDefinition
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ##   body: JObject (required)
  var body_603194 = newJObject()
  if body != nil:
    body_603194 = body
  result = call_603193.call(nil, nil, nil, nil, body_603194)

var getPipelineDefinition* = Call_GetPipelineDefinition_603180(
    name: "getPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.GetPipelineDefinition",
    validator: validate_GetPipelineDefinition_603181, base: "/",
    url: url_GetPipelineDefinition_603182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_603195 = ref object of OpenApiRestCall_602466
proc url_ListPipelines_603197(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_603196(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_603198 = query.getOrDefault("marker")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "marker", valid_603198
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
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603201 = header.getOrDefault("X-Amz-Target")
  valid_603201 = validateParameter(valid_603201, JString, required = true, default = newJString(
      "DataPipeline.ListPipelines"))
  if valid_603201 != nil:
    section.add "X-Amz-Target", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_ListPipelines_603195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_ListPipelines_603195; body: JsonNode;
          marker: string = ""): Recallable =
  ## listPipelines
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603210 = newJObject()
  var body_603211 = newJObject()
  add(query_603210, "marker", newJString(marker))
  if body != nil:
    body_603211 = body
  result = call_603209.call(nil, query_603210, nil, nil, body_603211)

var listPipelines* = Call_ListPipelines_603195(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ListPipelines",
    validator: validate_ListPipelines_603196, base: "/", url: url_ListPipelines_603197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForTask_603212 = ref object of OpenApiRestCall_602466
proc url_PollForTask_603214(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PollForTask_603213(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
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
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Security-Token")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Security-Token", valid_603216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603217 = header.getOrDefault("X-Amz-Target")
  valid_603217 = validateParameter(valid_603217, JString, required = true, default = newJString(
      "DataPipeline.PollForTask"))
  if valid_603217 != nil:
    section.add "X-Amz-Target", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Content-Sha256", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Algorithm")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Algorithm", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Signature")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Signature", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-SignedHeaders", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Credential")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Credential", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_PollForTask_603212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ## 
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_PollForTask_603212; body: JsonNode): Recallable =
  ## pollForTask
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ##   body: JObject (required)
  var body_603226 = newJObject()
  if body != nil:
    body_603226 = body
  result = call_603225.call(nil, nil, nil, nil, body_603226)

var pollForTask* = Call_PollForTask_603212(name: "pollForTask",
                                        meth: HttpMethod.HttpPost,
                                        host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.PollForTask",
                                        validator: validate_PollForTask_603213,
                                        base: "/", url: url_PollForTask_603214,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPipelineDefinition_603227 = ref object of OpenApiRestCall_602466
proc url_PutPipelineDefinition_603229(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPipelineDefinition_603228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
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
  var valid_603230 = header.getOrDefault("X-Amz-Date")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Date", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Security-Token")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Security-Token", valid_603231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603232 = header.getOrDefault("X-Amz-Target")
  valid_603232 = validateParameter(valid_603232, JString, required = true, default = newJString(
      "DataPipeline.PutPipelineDefinition"))
  if valid_603232 != nil:
    section.add "X-Amz-Target", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Content-Sha256", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Algorithm")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Algorithm", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Credential")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Credential", valid_603237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_PutPipelineDefinition_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_PutPipelineDefinition_603227; body: JsonNode): Recallable =
  ## putPipelineDefinition
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ##   body: JObject (required)
  var body_603241 = newJObject()
  if body != nil:
    body_603241 = body
  result = call_603240.call(nil, nil, nil, nil, body_603241)

var putPipelineDefinition* = Call_PutPipelineDefinition_603227(
    name: "putPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.PutPipelineDefinition",
    validator: validate_PutPipelineDefinition_603228, base: "/",
    url: url_PutPipelineDefinition_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_QueryObjects_603242 = ref object of OpenApiRestCall_602466
proc url_QueryObjects_603244(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_QueryObjects_603243(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_603245 = query.getOrDefault("marker")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "marker", valid_603245
  var valid_603246 = query.getOrDefault("limit")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "limit", valid_603246
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
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Security-Token")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Security-Token", valid_603248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603249 = header.getOrDefault("X-Amz-Target")
  valid_603249 = validateParameter(valid_603249, JString, required = true, default = newJString(
      "DataPipeline.QueryObjects"))
  if valid_603249 != nil:
    section.add "X-Amz-Target", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Content-Sha256", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Algorithm")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Algorithm", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Signature")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Signature", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-SignedHeaders", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Credential")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Credential", valid_603254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603256: Call_QueryObjects_603242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ## 
  let valid = call_603256.validator(path, query, header, formData, body)
  let scheme = call_603256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603256.url(scheme.get, call_603256.host, call_603256.base,
                         call_603256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603256, url, valid)

proc call*(call_603257: Call_QueryObjects_603242; body: JsonNode;
          marker: string = ""; limit: string = ""): Recallable =
  ## queryObjects
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_603258 = newJObject()
  var body_603259 = newJObject()
  add(query_603258, "marker", newJString(marker))
  if body != nil:
    body_603259 = body
  add(query_603258, "limit", newJString(limit))
  result = call_603257.call(nil, query_603258, nil, nil, body_603259)

var queryObjects* = Call_QueryObjects_603242(name: "queryObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.QueryObjects",
    validator: validate_QueryObjects_603243, base: "/", url: url_QueryObjects_603244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_603260 = ref object of OpenApiRestCall_602466
proc url_RemoveTags_603262(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTags_603261(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes existing tags from the specified pipeline.
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
  var valid_603263 = header.getOrDefault("X-Amz-Date")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Date", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Security-Token")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Security-Token", valid_603264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603265 = header.getOrDefault("X-Amz-Target")
  valid_603265 = validateParameter(valid_603265, JString, required = true, default = newJString(
      "DataPipeline.RemoveTags"))
  if valid_603265 != nil:
    section.add "X-Amz-Target", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Content-Sha256", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Algorithm")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Algorithm", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Signature")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Signature", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-SignedHeaders", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603272: Call_RemoveTags_603260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes existing tags from the specified pipeline.
  ## 
  let valid = call_603272.validator(path, query, header, formData, body)
  let scheme = call_603272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603272.url(scheme.get, call_603272.host, call_603272.base,
                         call_603272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603272, url, valid)

proc call*(call_603273: Call_RemoveTags_603260; body: JsonNode): Recallable =
  ## removeTags
  ## Removes existing tags from the specified pipeline.
  ##   body: JObject (required)
  var body_603274 = newJObject()
  if body != nil:
    body_603274 = body
  result = call_603273.call(nil, nil, nil, nil, body_603274)

var removeTags* = Call_RemoveTags_603260(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.RemoveTags",
                                      validator: validate_RemoveTags_603261,
                                      base: "/", url: url_RemoveTags_603262,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskProgress_603275 = ref object of OpenApiRestCall_602466
proc url_ReportTaskProgress_603277(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ReportTaskProgress_603276(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
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
  var valid_603278 = header.getOrDefault("X-Amz-Date")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Date", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Security-Token")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Security-Token", valid_603279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603280 = header.getOrDefault("X-Amz-Target")
  valid_603280 = validateParameter(valid_603280, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskProgress"))
  if valid_603280 != nil:
    section.add "X-Amz-Target", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Content-Sha256", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Algorithm")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Algorithm", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Signature")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Signature", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-SignedHeaders", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Credential")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Credential", valid_603285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603287: Call_ReportTaskProgress_603275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ## 
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603287, url, valid)

proc call*(call_603288: Call_ReportTaskProgress_603275; body: JsonNode): Recallable =
  ## reportTaskProgress
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ##   body: JObject (required)
  var body_603289 = newJObject()
  if body != nil:
    body_603289 = body
  result = call_603288.call(nil, nil, nil, nil, body_603289)

var reportTaskProgress* = Call_ReportTaskProgress_603275(
    name: "reportTaskProgress", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskProgress",
    validator: validate_ReportTaskProgress_603276, base: "/",
    url: url_ReportTaskProgress_603277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskRunnerHeartbeat_603290 = ref object of OpenApiRestCall_602466
proc url_ReportTaskRunnerHeartbeat_603292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ReportTaskRunnerHeartbeat_603291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
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
  var valid_603293 = header.getOrDefault("X-Amz-Date")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Date", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Security-Token")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Security-Token", valid_603294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603295 = header.getOrDefault("X-Amz-Target")
  valid_603295 = validateParameter(valid_603295, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskRunnerHeartbeat"))
  if valid_603295 != nil:
    section.add "X-Amz-Target", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Content-Sha256", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Algorithm")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Algorithm", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Signature")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Signature", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-SignedHeaders", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Credential")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Credential", valid_603300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603302: Call_ReportTaskRunnerHeartbeat_603290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ## 
  let valid = call_603302.validator(path, query, header, formData, body)
  let scheme = call_603302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603302.url(scheme.get, call_603302.host, call_603302.base,
                         call_603302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603302, url, valid)

proc call*(call_603303: Call_ReportTaskRunnerHeartbeat_603290; body: JsonNode): Recallable =
  ## reportTaskRunnerHeartbeat
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ##   body: JObject (required)
  var body_603304 = newJObject()
  if body != nil:
    body_603304 = body
  result = call_603303.call(nil, nil, nil, nil, body_603304)

var reportTaskRunnerHeartbeat* = Call_ReportTaskRunnerHeartbeat_603290(
    name: "reportTaskRunnerHeartbeat", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskRunnerHeartbeat",
    validator: validate_ReportTaskRunnerHeartbeat_603291, base: "/",
    url: url_ReportTaskRunnerHeartbeat_603292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetStatus_603305 = ref object of OpenApiRestCall_602466
proc url_SetStatus_603307(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetStatus_603306(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
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
  var valid_603308 = header.getOrDefault("X-Amz-Date")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Date", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Security-Token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Security-Token", valid_603309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603310 = header.getOrDefault("X-Amz-Target")
  valid_603310 = validateParameter(valid_603310, JString, required = true,
                                 default = newJString("DataPipeline.SetStatus"))
  if valid_603310 != nil:
    section.add "X-Amz-Target", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Content-Sha256", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Algorithm")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Algorithm", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Signature")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Signature", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-SignedHeaders", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Credential")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Credential", valid_603315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603317: Call_SetStatus_603305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ## 
  let valid = call_603317.validator(path, query, header, formData, body)
  let scheme = call_603317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603317.url(scheme.get, call_603317.host, call_603317.base,
                         call_603317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603317, url, valid)

proc call*(call_603318: Call_SetStatus_603305; body: JsonNode): Recallable =
  ## setStatus
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ##   body: JObject (required)
  var body_603319 = newJObject()
  if body != nil:
    body_603319 = body
  result = call_603318.call(nil, nil, nil, nil, body_603319)

var setStatus* = Call_SetStatus_603305(name: "setStatus", meth: HttpMethod.HttpPost,
                                    host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.SetStatus",
                                    validator: validate_SetStatus_603306,
                                    base: "/", url: url_SetStatus_603307,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTaskStatus_603320 = ref object of OpenApiRestCall_602466
proc url_SetTaskStatus_603322(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetTaskStatus_603321(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
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
      "DataPipeline.SetTaskStatus"))
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

proc call*(call_603332: Call_SetTaskStatus_603320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ## 
  let valid = call_603332.validator(path, query, header, formData, body)
  let scheme = call_603332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603332.url(scheme.get, call_603332.host, call_603332.base,
                         call_603332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603332, url, valid)

proc call*(call_603333: Call_SetTaskStatus_603320; body: JsonNode): Recallable =
  ## setTaskStatus
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ##   body: JObject (required)
  var body_603334 = newJObject()
  if body != nil:
    body_603334 = body
  result = call_603333.call(nil, nil, nil, nil, body_603334)

var setTaskStatus* = Call_SetTaskStatus_603320(name: "setTaskStatus",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.SetTaskStatus",
    validator: validate_SetTaskStatus_603321, base: "/", url: url_SetTaskStatus_603322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidatePipelineDefinition_603335 = ref object of OpenApiRestCall_602466
proc url_ValidatePipelineDefinition_603337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ValidatePipelineDefinition_603336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
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
  var valid_603338 = header.getOrDefault("X-Amz-Date")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Date", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Security-Token")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Security-Token", valid_603339
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603340 = header.getOrDefault("X-Amz-Target")
  valid_603340 = validateParameter(valid_603340, JString, required = true, default = newJString(
      "DataPipeline.ValidatePipelineDefinition"))
  if valid_603340 != nil:
    section.add "X-Amz-Target", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Content-Sha256", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Algorithm")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Algorithm", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Signature")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Signature", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-SignedHeaders", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Credential")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Credential", valid_603345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603347: Call_ValidatePipelineDefinition_603335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ## 
  let valid = call_603347.validator(path, query, header, formData, body)
  let scheme = call_603347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603347.url(scheme.get, call_603347.host, call_603347.base,
                         call_603347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603347, url, valid)

proc call*(call_603348: Call_ValidatePipelineDefinition_603335; body: JsonNode): Recallable =
  ## validatePipelineDefinition
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ##   body: JObject (required)
  var body_603349 = newJObject()
  if body != nil:
    body_603349 = body
  result = call_603348.call(nil, nil, nil, nil, body_603349)

var validatePipelineDefinition* = Call_ValidatePipelineDefinition_603335(
    name: "validatePipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ValidatePipelineDefinition",
    validator: validate_ValidatePipelineDefinition_603336, base: "/",
    url: url_ValidatePipelineDefinition_603337,
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
