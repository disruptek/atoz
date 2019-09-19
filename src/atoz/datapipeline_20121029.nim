
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_ActivatePipeline_772933 = ref object of OpenApiRestCall_772597
proc url_ActivatePipeline_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ActivatePipeline_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "DataPipeline.ActivatePipeline"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_ActivatePipeline_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_ActivatePipeline_772933; body: JsonNode): Recallable =
  ## activatePipeline
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var activatePipeline* = Call_ActivatePipeline_772933(name: "activatePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ActivatePipeline",
    validator: validate_ActivatePipeline_772934, base: "/",
    url: url_ActivatePipeline_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTags_773202 = ref object of OpenApiRestCall_772597
proc url_AddTags_773204(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTags_773203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true,
                                 default = newJString("DataPipeline.AddTags"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_AddTags_773202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or modifies tags for the specified pipeline.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_AddTags_773202; body: JsonNode): Recallable =
  ## addTags
  ## Adds or modifies tags for the specified pipeline.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var addTags* = Call_AddTags_773202(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "datapipeline.amazonaws.com",
                                route: "/#X-Amz-Target=DataPipeline.AddTags",
                                validator: validate_AddTags_773203, base: "/",
                                url: url_AddTags_773204,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_773217 = ref object of OpenApiRestCall_772597
proc url_CreatePipeline_773219(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePipeline_773218(path: JsonNode; query: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "DataPipeline.CreatePipeline"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_CreatePipeline_773217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_CreatePipeline_773217; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var createPipeline* = Call_CreatePipeline_773217(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.CreatePipeline",
    validator: validate_CreatePipeline_773218, base: "/", url: url_CreatePipeline_773219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivatePipeline_773232 = ref object of OpenApiRestCall_772597
proc url_DeactivatePipeline_773234(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeactivatePipeline_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "DataPipeline.DeactivatePipeline"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_DeactivatePipeline_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_DeactivatePipeline_773232; body: JsonNode): Recallable =
  ## deactivatePipeline
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var deactivatePipeline* = Call_DeactivatePipeline_773232(
    name: "deactivatePipeline", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeactivatePipeline",
    validator: validate_DeactivatePipeline_773233, base: "/",
    url: url_DeactivatePipeline_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_773247 = ref object of OpenApiRestCall_772597
proc url_DeletePipeline_773249(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePipeline_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "DataPipeline.DeletePipeline"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_DeletePipeline_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_DeletePipeline_773247; body: JsonNode): Recallable =
  ## deletePipeline
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var deletePipeline* = Call_DeletePipeline_773247(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeletePipeline",
    validator: validate_DeletePipeline_773248, base: "/", url: url_DeletePipeline_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObjects_773262 = ref object of OpenApiRestCall_772597
proc url_DescribeObjects_773264(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeObjects_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = query.getOrDefault("marker")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "marker", valid_773265
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
  var valid_773266 = header.getOrDefault("X-Amz-Date")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Date", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Security-Token")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Security-Token", valid_773267
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773268 = header.getOrDefault("X-Amz-Target")
  valid_773268 = validateParameter(valid_773268, JString, required = true, default = newJString(
      "DataPipeline.DescribeObjects"))
  if valid_773268 != nil:
    section.add "X-Amz-Target", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773275: Call_DescribeObjects_773262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ## 
  let valid = call_773275.validator(path, query, header, formData, body)
  let scheme = call_773275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773275.url(scheme.get, call_773275.host, call_773275.base,
                         call_773275.route, valid.getOrDefault("path"))
  result = hook(call_773275, url, valid)

proc call*(call_773276: Call_DescribeObjects_773262; body: JsonNode;
          marker: string = ""): Recallable =
  ## describeObjects
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773277 = newJObject()
  var body_773278 = newJObject()
  add(query_773277, "marker", newJString(marker))
  if body != nil:
    body_773278 = body
  result = call_773276.call(nil, query_773277, nil, nil, body_773278)

var describeObjects* = Call_DescribeObjects_773262(name: "describeObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribeObjects",
    validator: validate_DescribeObjects_773263, base: "/", url: url_DescribeObjects_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipelines_773280 = ref object of OpenApiRestCall_772597
proc url_DescribePipelines_773282(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePipelines_773281(path: JsonNode; query: JsonNode;
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
  var valid_773283 = header.getOrDefault("X-Amz-Date")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Date", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Security-Token")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Security-Token", valid_773284
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773285 = header.getOrDefault("X-Amz-Target")
  valid_773285 = validateParameter(valid_773285, JString, required = true, default = newJString(
      "DataPipeline.DescribePipelines"))
  if valid_773285 != nil:
    section.add "X-Amz-Target", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Content-Sha256", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Algorithm")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Algorithm", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Signature")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Signature", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-SignedHeaders", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Credential")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Credential", valid_773290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773292: Call_DescribePipelines_773280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ## 
  let valid = call_773292.validator(path, query, header, formData, body)
  let scheme = call_773292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773292.url(scheme.get, call_773292.host, call_773292.base,
                         call_773292.route, valid.getOrDefault("path"))
  result = hook(call_773292, url, valid)

proc call*(call_773293: Call_DescribePipelines_773280; body: JsonNode): Recallable =
  ## describePipelines
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ##   body: JObject (required)
  var body_773294 = newJObject()
  if body != nil:
    body_773294 = body
  result = call_773293.call(nil, nil, nil, nil, body_773294)

var describePipelines* = Call_DescribePipelines_773280(name: "describePipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribePipelines",
    validator: validate_DescribePipelines_773281, base: "/",
    url: url_DescribePipelines_773282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluateExpression_773295 = ref object of OpenApiRestCall_772597
proc url_EvaluateExpression_773297(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EvaluateExpression_773296(path: JsonNode; query: JsonNode;
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
  var valid_773298 = header.getOrDefault("X-Amz-Date")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Date", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Security-Token")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Security-Token", valid_773299
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773300 = header.getOrDefault("X-Amz-Target")
  valid_773300 = validateParameter(valid_773300, JString, required = true, default = newJString(
      "DataPipeline.EvaluateExpression"))
  if valid_773300 != nil:
    section.add "X-Amz-Target", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Content-Sha256", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Algorithm")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Algorithm", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Signature")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Signature", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-SignedHeaders", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Credential")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Credential", valid_773305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773307: Call_EvaluateExpression_773295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ## 
  let valid = call_773307.validator(path, query, header, formData, body)
  let scheme = call_773307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773307.url(scheme.get, call_773307.host, call_773307.base,
                         call_773307.route, valid.getOrDefault("path"))
  result = hook(call_773307, url, valid)

proc call*(call_773308: Call_EvaluateExpression_773295; body: JsonNode): Recallable =
  ## evaluateExpression
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ##   body: JObject (required)
  var body_773309 = newJObject()
  if body != nil:
    body_773309 = body
  result = call_773308.call(nil, nil, nil, nil, body_773309)

var evaluateExpression* = Call_EvaluateExpression_773295(
    name: "evaluateExpression", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.EvaluateExpression",
    validator: validate_EvaluateExpression_773296, base: "/",
    url: url_EvaluateExpression_773297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineDefinition_773310 = ref object of OpenApiRestCall_772597
proc url_GetPipelineDefinition_773312(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPipelineDefinition_773311(path: JsonNode; query: JsonNode;
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
  var valid_773313 = header.getOrDefault("X-Amz-Date")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Date", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Security-Token")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Security-Token", valid_773314
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773315 = header.getOrDefault("X-Amz-Target")
  valid_773315 = validateParameter(valid_773315, JString, required = true, default = newJString(
      "DataPipeline.GetPipelineDefinition"))
  if valid_773315 != nil:
    section.add "X-Amz-Target", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Content-Sha256", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Algorithm")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Algorithm", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Signature")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Signature", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-SignedHeaders", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Credential")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Credential", valid_773320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773322: Call_GetPipelineDefinition_773310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ## 
  let valid = call_773322.validator(path, query, header, formData, body)
  let scheme = call_773322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773322.url(scheme.get, call_773322.host, call_773322.base,
                         call_773322.route, valid.getOrDefault("path"))
  result = hook(call_773322, url, valid)

proc call*(call_773323: Call_GetPipelineDefinition_773310; body: JsonNode): Recallable =
  ## getPipelineDefinition
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ##   body: JObject (required)
  var body_773324 = newJObject()
  if body != nil:
    body_773324 = body
  result = call_773323.call(nil, nil, nil, nil, body_773324)

var getPipelineDefinition* = Call_GetPipelineDefinition_773310(
    name: "getPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.GetPipelineDefinition",
    validator: validate_GetPipelineDefinition_773311, base: "/",
    url: url_GetPipelineDefinition_773312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_773325 = ref object of OpenApiRestCall_772597
proc url_ListPipelines_773327(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPipelines_773326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773328 = query.getOrDefault("marker")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "marker", valid_773328
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
  var valid_773329 = header.getOrDefault("X-Amz-Date")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Date", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Security-Token")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Security-Token", valid_773330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773331 = header.getOrDefault("X-Amz-Target")
  valid_773331 = validateParameter(valid_773331, JString, required = true, default = newJString(
      "DataPipeline.ListPipelines"))
  if valid_773331 != nil:
    section.add "X-Amz-Target", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Content-Sha256", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Algorithm")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Algorithm", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Signature")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Signature", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-SignedHeaders", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Credential")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Credential", valid_773336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773338: Call_ListPipelines_773325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ## 
  let valid = call_773338.validator(path, query, header, formData, body)
  let scheme = call_773338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773338.url(scheme.get, call_773338.host, call_773338.base,
                         call_773338.route, valid.getOrDefault("path"))
  result = hook(call_773338, url, valid)

proc call*(call_773339: Call_ListPipelines_773325; body: JsonNode;
          marker: string = ""): Recallable =
  ## listPipelines
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773340 = newJObject()
  var body_773341 = newJObject()
  add(query_773340, "marker", newJString(marker))
  if body != nil:
    body_773341 = body
  result = call_773339.call(nil, query_773340, nil, nil, body_773341)

var listPipelines* = Call_ListPipelines_773325(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ListPipelines",
    validator: validate_ListPipelines_773326, base: "/", url: url_ListPipelines_773327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForTask_773342 = ref object of OpenApiRestCall_772597
proc url_PollForTask_773344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PollForTask_773343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773345 = header.getOrDefault("X-Amz-Date")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Date", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Security-Token")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Security-Token", valid_773346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773347 = header.getOrDefault("X-Amz-Target")
  valid_773347 = validateParameter(valid_773347, JString, required = true, default = newJString(
      "DataPipeline.PollForTask"))
  if valid_773347 != nil:
    section.add "X-Amz-Target", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Content-Sha256", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Algorithm")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Algorithm", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Signature")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Signature", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-SignedHeaders", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Credential")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Credential", valid_773352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773354: Call_PollForTask_773342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ## 
  let valid = call_773354.validator(path, query, header, formData, body)
  let scheme = call_773354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773354.url(scheme.get, call_773354.host, call_773354.base,
                         call_773354.route, valid.getOrDefault("path"))
  result = hook(call_773354, url, valid)

proc call*(call_773355: Call_PollForTask_773342; body: JsonNode): Recallable =
  ## pollForTask
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ##   body: JObject (required)
  var body_773356 = newJObject()
  if body != nil:
    body_773356 = body
  result = call_773355.call(nil, nil, nil, nil, body_773356)

var pollForTask* = Call_PollForTask_773342(name: "pollForTask",
                                        meth: HttpMethod.HttpPost,
                                        host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.PollForTask",
                                        validator: validate_PollForTask_773343,
                                        base: "/", url: url_PollForTask_773344,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPipelineDefinition_773357 = ref object of OpenApiRestCall_772597
proc url_PutPipelineDefinition_773359(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutPipelineDefinition_773358(path: JsonNode; query: JsonNode;
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
  var valid_773360 = header.getOrDefault("X-Amz-Date")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Date", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Security-Token")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Security-Token", valid_773361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773362 = header.getOrDefault("X-Amz-Target")
  valid_773362 = validateParameter(valid_773362, JString, required = true, default = newJString(
      "DataPipeline.PutPipelineDefinition"))
  if valid_773362 != nil:
    section.add "X-Amz-Target", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Content-Sha256", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Algorithm")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Algorithm", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Signature")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Signature", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-SignedHeaders", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Credential")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Credential", valid_773367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773369: Call_PutPipelineDefinition_773357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ## 
  let valid = call_773369.validator(path, query, header, formData, body)
  let scheme = call_773369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773369.url(scheme.get, call_773369.host, call_773369.base,
                         call_773369.route, valid.getOrDefault("path"))
  result = hook(call_773369, url, valid)

proc call*(call_773370: Call_PutPipelineDefinition_773357; body: JsonNode): Recallable =
  ## putPipelineDefinition
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ##   body: JObject (required)
  var body_773371 = newJObject()
  if body != nil:
    body_773371 = body
  result = call_773370.call(nil, nil, nil, nil, body_773371)

var putPipelineDefinition* = Call_PutPipelineDefinition_773357(
    name: "putPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.PutPipelineDefinition",
    validator: validate_PutPipelineDefinition_773358, base: "/",
    url: url_PutPipelineDefinition_773359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_QueryObjects_773372 = ref object of OpenApiRestCall_772597
proc url_QueryObjects_773374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_QueryObjects_773373(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773375 = query.getOrDefault("marker")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "marker", valid_773375
  var valid_773376 = query.getOrDefault("limit")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "limit", valid_773376
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
  var valid_773377 = header.getOrDefault("X-Amz-Date")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Date", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Security-Token")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Security-Token", valid_773378
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773379 = header.getOrDefault("X-Amz-Target")
  valid_773379 = validateParameter(valid_773379, JString, required = true, default = newJString(
      "DataPipeline.QueryObjects"))
  if valid_773379 != nil:
    section.add "X-Amz-Target", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Content-Sha256", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Algorithm")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Algorithm", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Signature")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Signature", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-SignedHeaders", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Credential")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Credential", valid_773384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773386: Call_QueryObjects_773372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ## 
  let valid = call_773386.validator(path, query, header, formData, body)
  let scheme = call_773386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773386.url(scheme.get, call_773386.host, call_773386.base,
                         call_773386.route, valid.getOrDefault("path"))
  result = hook(call_773386, url, valid)

proc call*(call_773387: Call_QueryObjects_773372; body: JsonNode;
          marker: string = ""; limit: string = ""): Recallable =
  ## queryObjects
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ##   marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_773388 = newJObject()
  var body_773389 = newJObject()
  add(query_773388, "marker", newJString(marker))
  if body != nil:
    body_773389 = body
  add(query_773388, "limit", newJString(limit))
  result = call_773387.call(nil, query_773388, nil, nil, body_773389)

var queryObjects* = Call_QueryObjects_773372(name: "queryObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.QueryObjects",
    validator: validate_QueryObjects_773373, base: "/", url: url_QueryObjects_773374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_773390 = ref object of OpenApiRestCall_772597
proc url_RemoveTags_773392(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTags_773391(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773393 = header.getOrDefault("X-Amz-Date")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Date", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Security-Token")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Security-Token", valid_773394
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773395 = header.getOrDefault("X-Amz-Target")
  valid_773395 = validateParameter(valid_773395, JString, required = true, default = newJString(
      "DataPipeline.RemoveTags"))
  if valid_773395 != nil:
    section.add "X-Amz-Target", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Content-Sha256", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Algorithm")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Algorithm", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Signature")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Signature", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-SignedHeaders", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Credential")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Credential", valid_773400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773402: Call_RemoveTags_773390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes existing tags from the specified pipeline.
  ## 
  let valid = call_773402.validator(path, query, header, formData, body)
  let scheme = call_773402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773402.url(scheme.get, call_773402.host, call_773402.base,
                         call_773402.route, valid.getOrDefault("path"))
  result = hook(call_773402, url, valid)

proc call*(call_773403: Call_RemoveTags_773390; body: JsonNode): Recallable =
  ## removeTags
  ## Removes existing tags from the specified pipeline.
  ##   body: JObject (required)
  var body_773404 = newJObject()
  if body != nil:
    body_773404 = body
  result = call_773403.call(nil, nil, nil, nil, body_773404)

var removeTags* = Call_RemoveTags_773390(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.RemoveTags",
                                      validator: validate_RemoveTags_773391,
                                      base: "/", url: url_RemoveTags_773392,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskProgress_773405 = ref object of OpenApiRestCall_772597
proc url_ReportTaskProgress_773407(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ReportTaskProgress_773406(path: JsonNode; query: JsonNode;
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
  var valid_773408 = header.getOrDefault("X-Amz-Date")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Date", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Security-Token")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Security-Token", valid_773409
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773410 = header.getOrDefault("X-Amz-Target")
  valid_773410 = validateParameter(valid_773410, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskProgress"))
  if valid_773410 != nil:
    section.add "X-Amz-Target", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Content-Sha256", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Algorithm")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Algorithm", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Signature")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Signature", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-SignedHeaders", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Credential")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Credential", valid_773415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773417: Call_ReportTaskProgress_773405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ## 
  let valid = call_773417.validator(path, query, header, formData, body)
  let scheme = call_773417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773417.url(scheme.get, call_773417.host, call_773417.base,
                         call_773417.route, valid.getOrDefault("path"))
  result = hook(call_773417, url, valid)

proc call*(call_773418: Call_ReportTaskProgress_773405; body: JsonNode): Recallable =
  ## reportTaskProgress
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ##   body: JObject (required)
  var body_773419 = newJObject()
  if body != nil:
    body_773419 = body
  result = call_773418.call(nil, nil, nil, nil, body_773419)

var reportTaskProgress* = Call_ReportTaskProgress_773405(
    name: "reportTaskProgress", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskProgress",
    validator: validate_ReportTaskProgress_773406, base: "/",
    url: url_ReportTaskProgress_773407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskRunnerHeartbeat_773420 = ref object of OpenApiRestCall_772597
proc url_ReportTaskRunnerHeartbeat_773422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ReportTaskRunnerHeartbeat_773421(path: JsonNode; query: JsonNode;
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
  var valid_773423 = header.getOrDefault("X-Amz-Date")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Date", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Security-Token")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Security-Token", valid_773424
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773425 = header.getOrDefault("X-Amz-Target")
  valid_773425 = validateParameter(valid_773425, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskRunnerHeartbeat"))
  if valid_773425 != nil:
    section.add "X-Amz-Target", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Content-Sha256", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Algorithm")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Algorithm", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Signature")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Signature", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-SignedHeaders", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Credential")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Credential", valid_773430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773432: Call_ReportTaskRunnerHeartbeat_773420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ## 
  let valid = call_773432.validator(path, query, header, formData, body)
  let scheme = call_773432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773432.url(scheme.get, call_773432.host, call_773432.base,
                         call_773432.route, valid.getOrDefault("path"))
  result = hook(call_773432, url, valid)

proc call*(call_773433: Call_ReportTaskRunnerHeartbeat_773420; body: JsonNode): Recallable =
  ## reportTaskRunnerHeartbeat
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ##   body: JObject (required)
  var body_773434 = newJObject()
  if body != nil:
    body_773434 = body
  result = call_773433.call(nil, nil, nil, nil, body_773434)

var reportTaskRunnerHeartbeat* = Call_ReportTaskRunnerHeartbeat_773420(
    name: "reportTaskRunnerHeartbeat", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskRunnerHeartbeat",
    validator: validate_ReportTaskRunnerHeartbeat_773421, base: "/",
    url: url_ReportTaskRunnerHeartbeat_773422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetStatus_773435 = ref object of OpenApiRestCall_772597
proc url_SetStatus_773437(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetStatus_773436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773438 = header.getOrDefault("X-Amz-Date")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Date", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Security-Token")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Security-Token", valid_773439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773440 = header.getOrDefault("X-Amz-Target")
  valid_773440 = validateParameter(valid_773440, JString, required = true,
                                 default = newJString("DataPipeline.SetStatus"))
  if valid_773440 != nil:
    section.add "X-Amz-Target", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Content-Sha256", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Algorithm")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Algorithm", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Signature")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Signature", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-SignedHeaders", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Credential")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Credential", valid_773445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773447: Call_SetStatus_773435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ## 
  let valid = call_773447.validator(path, query, header, formData, body)
  let scheme = call_773447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773447.url(scheme.get, call_773447.host, call_773447.base,
                         call_773447.route, valid.getOrDefault("path"))
  result = hook(call_773447, url, valid)

proc call*(call_773448: Call_SetStatus_773435; body: JsonNode): Recallable =
  ## setStatus
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ##   body: JObject (required)
  var body_773449 = newJObject()
  if body != nil:
    body_773449 = body
  result = call_773448.call(nil, nil, nil, nil, body_773449)

var setStatus* = Call_SetStatus_773435(name: "setStatus", meth: HttpMethod.HttpPost,
                                    host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.SetStatus",
                                    validator: validate_SetStatus_773436,
                                    base: "/", url: url_SetStatus_773437,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTaskStatus_773450 = ref object of OpenApiRestCall_772597
proc url_SetTaskStatus_773452(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetTaskStatus_773451(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773453 = header.getOrDefault("X-Amz-Date")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Date", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Security-Token")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Security-Token", valid_773454
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773455 = header.getOrDefault("X-Amz-Target")
  valid_773455 = validateParameter(valid_773455, JString, required = true, default = newJString(
      "DataPipeline.SetTaskStatus"))
  if valid_773455 != nil:
    section.add "X-Amz-Target", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Content-Sha256", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Algorithm")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Algorithm", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Signature")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Signature", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-SignedHeaders", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Credential")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Credential", valid_773460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773462: Call_SetTaskStatus_773450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ## 
  let valid = call_773462.validator(path, query, header, formData, body)
  let scheme = call_773462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773462.url(scheme.get, call_773462.host, call_773462.base,
                         call_773462.route, valid.getOrDefault("path"))
  result = hook(call_773462, url, valid)

proc call*(call_773463: Call_SetTaskStatus_773450; body: JsonNode): Recallable =
  ## setTaskStatus
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ##   body: JObject (required)
  var body_773464 = newJObject()
  if body != nil:
    body_773464 = body
  result = call_773463.call(nil, nil, nil, nil, body_773464)

var setTaskStatus* = Call_SetTaskStatus_773450(name: "setTaskStatus",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.SetTaskStatus",
    validator: validate_SetTaskStatus_773451, base: "/", url: url_SetTaskStatus_773452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidatePipelineDefinition_773465 = ref object of OpenApiRestCall_772597
proc url_ValidatePipelineDefinition_773467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ValidatePipelineDefinition_773466(path: JsonNode; query: JsonNode;
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
  var valid_773468 = header.getOrDefault("X-Amz-Date")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Date", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Security-Token")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Security-Token", valid_773469
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773470 = header.getOrDefault("X-Amz-Target")
  valid_773470 = validateParameter(valid_773470, JString, required = true, default = newJString(
      "DataPipeline.ValidatePipelineDefinition"))
  if valid_773470 != nil:
    section.add "X-Amz-Target", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Content-Sha256", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Algorithm")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Algorithm", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Signature")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Signature", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-SignedHeaders", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Credential")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Credential", valid_773475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773477: Call_ValidatePipelineDefinition_773465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ## 
  let valid = call_773477.validator(path, query, header, formData, body)
  let scheme = call_773477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773477.url(scheme.get, call_773477.host, call_773477.base,
                         call_773477.route, valid.getOrDefault("path"))
  result = hook(call_773477, url, valid)

proc call*(call_773478: Call_ValidatePipelineDefinition_773465; body: JsonNode): Recallable =
  ## validatePipelineDefinition
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ##   body: JObject (required)
  var body_773479 = newJObject()
  if body != nil:
    body_773479 = body
  result = call_773478.call(nil, nil, nil, nil, body_773479)

var validatePipelineDefinition* = Call_ValidatePipelineDefinition_773465(
    name: "validatePipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ValidatePipelineDefinition",
    validator: validate_ValidatePipelineDefinition_773466, base: "/",
    url: url_ValidatePipelineDefinition_773467,
    schemes: {Scheme.Https, Scheme.Http})
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
