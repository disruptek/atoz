
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ActivatePipeline_605927 = ref object of OpenApiRestCall_605589
proc url_ActivatePipeline_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ActivatePipeline_605928(path: JsonNode; query: JsonNode;
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "DataPipeline.ActivatePipeline"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_ActivatePipeline_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_ActivatePipeline_605927; body: JsonNode): Recallable =
  ## activatePipeline
  ## <p>Validates the specified pipeline and starts processing pipeline tasks. If the pipeline does not pass validation, activation fails.</p> <p>If you need to pause the pipeline to investigate an issue with a component, such as a data source or script, call <a>DeactivatePipeline</a>.</p> <p>To activate a finished pipeline, modify the end date for the pipeline and then activate it.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var activatePipeline* = Call_ActivatePipeline_605927(name: "activatePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ActivatePipeline",
    validator: validate_ActivatePipeline_605928, base: "/",
    url: url_ActivatePipeline_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTags_606196 = ref object of OpenApiRestCall_605589
proc url_AddTags_606198(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_606197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true,
                                 default = newJString("DataPipeline.AddTags"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_AddTags_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or modifies tags for the specified pipeline.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AddTags_606196; body: JsonNode): Recallable =
  ## addTags
  ## Adds or modifies tags for the specified pipeline.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var addTags* = Call_AddTags_606196(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "datapipeline.amazonaws.com",
                                route: "/#X-Amz-Target=DataPipeline.AddTags",
                                validator: validate_AddTags_606197, base: "/",
                                url: url_AddTags_606198,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_606211 = ref object of OpenApiRestCall_605589
proc url_CreatePipeline_606213(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_606212(path: JsonNode; query: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "DataPipeline.CreatePipeline"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreatePipeline_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreatePipeline_606211; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a new, empty pipeline. Use <a>PutPipelineDefinition</a> to populate the pipeline.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createPipeline* = Call_CreatePipeline_606211(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.CreatePipeline",
    validator: validate_CreatePipeline_606212, base: "/", url: url_CreatePipeline_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivatePipeline_606226 = ref object of OpenApiRestCall_605589
proc url_DeactivatePipeline_606228(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivatePipeline_606227(path: JsonNode; query: JsonNode;
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "DataPipeline.DeactivatePipeline"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DeactivatePipeline_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DeactivatePipeline_606226; body: JsonNode): Recallable =
  ## deactivatePipeline
  ## <p>Deactivates the specified running pipeline. The pipeline is set to the <code>DEACTIVATING</code> state until the deactivation process completes.</p> <p>To resume a deactivated pipeline, use <a>ActivatePipeline</a>. By default, the pipeline resumes from the last completed execution. Optionally, you can specify the date and time to resume the pipeline.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var deactivatePipeline* = Call_DeactivatePipeline_606226(
    name: "deactivatePipeline", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeactivatePipeline",
    validator: validate_DeactivatePipeline_606227, base: "/",
    url: url_DeactivatePipeline_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_606241 = ref object of OpenApiRestCall_605589
proc url_DeletePipeline_606243(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_606242(path: JsonNode; query: JsonNode;
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "DataPipeline.DeletePipeline"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeletePipeline_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeletePipeline_606241; body: JsonNode): Recallable =
  ## deletePipeline
  ## <p>Deletes a pipeline, its pipeline definition, and its run history. AWS Data Pipeline attempts to cancel instances associated with the pipeline that are currently being processed by task runners.</p> <p>Deleting a pipeline cannot be undone. You cannot query or restore a deleted pipeline. To temporarily pause a pipeline instead of deleting it, call <a>SetStatus</a> with the status set to <code>PAUSE</code> on individual components. Components that are paused by <a>SetStatus</a> can be resumed.</p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deletePipeline* = Call_DeletePipeline_606241(name: "deletePipeline",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DeletePipeline",
    validator: validate_DeletePipeline_606242, base: "/", url: url_DeletePipeline_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObjects_606256 = ref object of OpenApiRestCall_605589
proc url_DescribeObjects_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeObjects_606257(path: JsonNode; query: JsonNode;
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
  var valid_606259 = query.getOrDefault("marker")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "marker", valid_606259
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
  var valid_606260 = header.getOrDefault("X-Amz-Target")
  valid_606260 = validateParameter(valid_606260, JString, required = true, default = newJString(
      "DataPipeline.DescribeObjects"))
  if valid_606260 != nil:
    section.add "X-Amz-Target", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606269: Call_DescribeObjects_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ## 
  let valid = call_606269.validator(path, query, header, formData, body)
  let scheme = call_606269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606269.url(scheme.get, call_606269.host, call_606269.base,
                         call_606269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606269, url, valid)

proc call*(call_606270: Call_DescribeObjects_606256; body: JsonNode;
          marker: string = ""): Recallable =
  ## describeObjects
  ## Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
  ##   body: JObject (required)
  ##   marker: string
  ##         : Pagination token
  var query_606271 = newJObject()
  var body_606272 = newJObject()
  if body != nil:
    body_606272 = body
  add(query_606271, "marker", newJString(marker))
  result = call_606270.call(nil, query_606271, nil, nil, body_606272)

var describeObjects* = Call_DescribeObjects_606256(name: "describeObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribeObjects",
    validator: validate_DescribeObjects_606257, base: "/", url: url_DescribeObjects_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipelines_606274 = ref object of OpenApiRestCall_605589
proc url_DescribePipelines_606276(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePipelines_606275(path: JsonNode; query: JsonNode;
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
  var valid_606277 = header.getOrDefault("X-Amz-Target")
  valid_606277 = validateParameter(valid_606277, JString, required = true, default = newJString(
      "DataPipeline.DescribePipelines"))
  if valid_606277 != nil:
    section.add "X-Amz-Target", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606286: Call_DescribePipelines_606274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ## 
  let valid = call_606286.validator(path, query, header, formData, body)
  let scheme = call_606286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606286.url(scheme.get, call_606286.host, call_606286.base,
                         call_606286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606286, url, valid)

proc call*(call_606287: Call_DescribePipelines_606274; body: JsonNode): Recallable =
  ## describePipelines
  ## <p>Retrieves metadata about one or more pipelines. The information retrieved includes the name of the pipeline, the pipeline identifier, its current state, and the user account that owns the pipeline. Using account credentials, you can retrieve metadata about pipelines that you or your IAM users have created. If you are using an IAM user account, you can retrieve metadata about only those pipelines for which you have read permissions.</p> <p>To retrieve the full pipeline definition instead of metadata about the pipeline, call <a>GetPipelineDefinition</a>.</p>
  ##   body: JObject (required)
  var body_606288 = newJObject()
  if body != nil:
    body_606288 = body
  result = call_606287.call(nil, nil, nil, nil, body_606288)

var describePipelines* = Call_DescribePipelines_606274(name: "describePipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.DescribePipelines",
    validator: validate_DescribePipelines_606275, base: "/",
    url: url_DescribePipelines_606276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluateExpression_606289 = ref object of OpenApiRestCall_605589
proc url_EvaluateExpression_606291(protocol: Scheme; host: string; base: string;
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

proc validate_EvaluateExpression_606290(path: JsonNode; query: JsonNode;
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
  var valid_606292 = header.getOrDefault("X-Amz-Target")
  valid_606292 = validateParameter(valid_606292, JString, required = true, default = newJString(
      "DataPipeline.EvaluateExpression"))
  if valid_606292 != nil:
    section.add "X-Amz-Target", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Signature")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Signature", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Content-Sha256", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Date")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Date", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Credential")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Credential", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Security-Token")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Security-Token", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Algorithm")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Algorithm", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-SignedHeaders", valid_606299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606301: Call_EvaluateExpression_606289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ## 
  let valid = call_606301.validator(path, query, header, formData, body)
  let scheme = call_606301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606301.url(scheme.get, call_606301.host, call_606301.base,
                         call_606301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606301, url, valid)

proc call*(call_606302: Call_EvaluateExpression_606289; body: JsonNode): Recallable =
  ## evaluateExpression
  ## Task runners call <code>EvaluateExpression</code> to evaluate a string in the context of the specified object. For example, a task runner can evaluate SQL queries stored in Amazon S3.
  ##   body: JObject (required)
  var body_606303 = newJObject()
  if body != nil:
    body_606303 = body
  result = call_606302.call(nil, nil, nil, nil, body_606303)

var evaluateExpression* = Call_EvaluateExpression_606289(
    name: "evaluateExpression", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.EvaluateExpression",
    validator: validate_EvaluateExpression_606290, base: "/",
    url: url_EvaluateExpression_606291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPipelineDefinition_606304 = ref object of OpenApiRestCall_605589
proc url_GetPipelineDefinition_606306(protocol: Scheme; host: string; base: string;
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

proc validate_GetPipelineDefinition_606305(path: JsonNode; query: JsonNode;
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
  var valid_606307 = header.getOrDefault("X-Amz-Target")
  valid_606307 = validateParameter(valid_606307, JString, required = true, default = newJString(
      "DataPipeline.GetPipelineDefinition"))
  if valid_606307 != nil:
    section.add "X-Amz-Target", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Signature")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Signature", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Content-Sha256", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Date")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Date", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Credential")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Credential", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Security-Token")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Security-Token", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Algorithm")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Algorithm", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-SignedHeaders", valid_606314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606316: Call_GetPipelineDefinition_606304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ## 
  let valid = call_606316.validator(path, query, header, formData, body)
  let scheme = call_606316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606316.url(scheme.get, call_606316.host, call_606316.base,
                         call_606316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606316, url, valid)

proc call*(call_606317: Call_GetPipelineDefinition_606304; body: JsonNode): Recallable =
  ## getPipelineDefinition
  ## Gets the definition of the specified pipeline. You can call <code>GetPipelineDefinition</code> to retrieve the pipeline definition that you provided using <a>PutPipelineDefinition</a>.
  ##   body: JObject (required)
  var body_606318 = newJObject()
  if body != nil:
    body_606318 = body
  result = call_606317.call(nil, nil, nil, nil, body_606318)

var getPipelineDefinition* = Call_GetPipelineDefinition_606304(
    name: "getPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.GetPipelineDefinition",
    validator: validate_GetPipelineDefinition_606305, base: "/",
    url: url_GetPipelineDefinition_606306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_606319 = ref object of OpenApiRestCall_605589
proc url_ListPipelines_606321(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_606320(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606322 = query.getOrDefault("marker")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "marker", valid_606322
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
  var valid_606323 = header.getOrDefault("X-Amz-Target")
  valid_606323 = validateParameter(valid_606323, JString, required = true, default = newJString(
      "DataPipeline.ListPipelines"))
  if valid_606323 != nil:
    section.add "X-Amz-Target", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Signature")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Signature", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Content-Sha256", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Date")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Date", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Credential")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Credential", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Security-Token")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Security-Token", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Algorithm")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Algorithm", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-SignedHeaders", valid_606330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606332: Call_ListPipelines_606319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ## 
  let valid = call_606332.validator(path, query, header, formData, body)
  let scheme = call_606332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606332.url(scheme.get, call_606332.host, call_606332.base,
                         call_606332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606332, url, valid)

proc call*(call_606333: Call_ListPipelines_606319; body: JsonNode;
          marker: string = ""): Recallable =
  ## listPipelines
  ## Lists the pipeline identifiers for all active pipelines that you have permission to access.
  ##   body: JObject (required)
  ##   marker: string
  ##         : Pagination token
  var query_606334 = newJObject()
  var body_606335 = newJObject()
  if body != nil:
    body_606335 = body
  add(query_606334, "marker", newJString(marker))
  result = call_606333.call(nil, query_606334, nil, nil, body_606335)

var listPipelines* = Call_ListPipelines_606319(name: "listPipelines",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ListPipelines",
    validator: validate_ListPipelines_606320, base: "/", url: url_ListPipelines_606321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForTask_606336 = ref object of OpenApiRestCall_605589
proc url_PollForTask_606338(protocol: Scheme; host: string; base: string;
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

proc validate_PollForTask_606337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606339 = header.getOrDefault("X-Amz-Target")
  valid_606339 = validateParameter(valid_606339, JString, required = true, default = newJString(
      "DataPipeline.PollForTask"))
  if valid_606339 != nil:
    section.add "X-Amz-Target", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Signature")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Signature", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Content-Sha256", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Date")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Date", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Credential")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Credential", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Security-Token")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Security-Token", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Algorithm")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Algorithm", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-SignedHeaders", valid_606346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606348: Call_PollForTask_606336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ## 
  let valid = call_606348.validator(path, query, header, formData, body)
  let scheme = call_606348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606348.url(scheme.get, call_606348.host, call_606348.base,
                         call_606348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606348, url, valid)

proc call*(call_606349: Call_PollForTask_606336; body: JsonNode): Recallable =
  ## pollForTask
  ## <p>Task runners call <code>PollForTask</code> to receive a task to perform from AWS Data Pipeline. The task runner specifies which tasks it can perform by setting a value for the <code>workerGroup</code> parameter. The task returned can come from any of the pipelines that match the <code>workerGroup</code> value passed in by the task runner and that was launched using the IAM user credentials specified by the task runner.</p> <p>If tasks are ready in the work queue, <code>PollForTask</code> returns a response immediately. If no tasks are available in the queue, <code>PollForTask</code> uses long-polling and holds on to a poll connection for up to a 90 seconds, during which time the first newly scheduled task is handed to the task runner. To accomodate this, set the socket timeout in your task runner to 90 seconds. The task runner should not call <code>PollForTask</code> again on the same <code>workerGroup</code> until it receives a response, and this can take up to 90 seconds. </p>
  ##   body: JObject (required)
  var body_606350 = newJObject()
  if body != nil:
    body_606350 = body
  result = call_606349.call(nil, nil, nil, nil, body_606350)

var pollForTask* = Call_PollForTask_606336(name: "pollForTask",
                                        meth: HttpMethod.HttpPost,
                                        host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.PollForTask",
                                        validator: validate_PollForTask_606337,
                                        base: "/", url: url_PollForTask_606338,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPipelineDefinition_606351 = ref object of OpenApiRestCall_605589
proc url_PutPipelineDefinition_606353(protocol: Scheme; host: string; base: string;
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

proc validate_PutPipelineDefinition_606352(path: JsonNode; query: JsonNode;
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
  var valid_606354 = header.getOrDefault("X-Amz-Target")
  valid_606354 = validateParameter(valid_606354, JString, required = true, default = newJString(
      "DataPipeline.PutPipelineDefinition"))
  if valid_606354 != nil:
    section.add "X-Amz-Target", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Signature")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Signature", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Content-Sha256", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Date")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Date", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Credential")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Credential", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Security-Token")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Security-Token", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Algorithm")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Algorithm", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-SignedHeaders", valid_606361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606363: Call_PutPipelineDefinition_606351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ## 
  let valid = call_606363.validator(path, query, header, formData, body)
  let scheme = call_606363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606363.url(scheme.get, call_606363.host, call_606363.base,
                         call_606363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606363, url, valid)

proc call*(call_606364: Call_PutPipelineDefinition_606351; body: JsonNode): Recallable =
  ## putPipelineDefinition
  ## <p>Adds tasks, schedules, and preconditions to the specified pipeline. You can use <code>PutPipelineDefinition</code> to populate a new pipeline.</p> <p> <code>PutPipelineDefinition</code> also validates the configuration as it adds it to the pipeline. Changes to the pipeline are saved unless one of the following three validation errors exists in the pipeline. </p> <ol> <li>An object is missing a name or identifier field.</li> <li>A string or reference field is empty.</li> <li>The number of objects in the pipeline exceeds the maximum allowed objects.</li> <li>The pipeline is in a FINISHED state.</li> </ol> <p> Pipeline object definitions are passed to the <code>PutPipelineDefinition</code> action and returned by the <a>GetPipelineDefinition</a> action. </p>
  ##   body: JObject (required)
  var body_606365 = newJObject()
  if body != nil:
    body_606365 = body
  result = call_606364.call(nil, nil, nil, nil, body_606365)

var putPipelineDefinition* = Call_PutPipelineDefinition_606351(
    name: "putPipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.PutPipelineDefinition",
    validator: validate_PutPipelineDefinition_606352, base: "/",
    url: url_PutPipelineDefinition_606353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_QueryObjects_606366 = ref object of OpenApiRestCall_605589
proc url_QueryObjects_606368(protocol: Scheme; host: string; base: string;
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

proc validate_QueryObjects_606367(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JString
  ##        : Pagination limit
  ##   marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_606369 = query.getOrDefault("limit")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "limit", valid_606369
  var valid_606370 = query.getOrDefault("marker")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "marker", valid_606370
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
  var valid_606371 = header.getOrDefault("X-Amz-Target")
  valid_606371 = validateParameter(valid_606371, JString, required = true, default = newJString(
      "DataPipeline.QueryObjects"))
  if valid_606371 != nil:
    section.add "X-Amz-Target", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Signature")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Signature", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Content-Sha256", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Date")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Date", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Credential")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Credential", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Security-Token")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Security-Token", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Algorithm")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Algorithm", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-SignedHeaders", valid_606378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_QueryObjects_606366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ## 
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_QueryObjects_606366; body: JsonNode; limit: string = "";
          marker: string = ""): Recallable =
  ## queryObjects
  ## Queries the specified pipeline for the names of objects that match the specified set of conditions.
  ##   limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   marker: string
  ##         : Pagination token
  var query_606382 = newJObject()
  var body_606383 = newJObject()
  add(query_606382, "limit", newJString(limit))
  if body != nil:
    body_606383 = body
  add(query_606382, "marker", newJString(marker))
  result = call_606381.call(nil, query_606382, nil, nil, body_606383)

var queryObjects* = Call_QueryObjects_606366(name: "queryObjects",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.QueryObjects",
    validator: validate_QueryObjects_606367, base: "/", url: url_QueryObjects_606368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_606384 = ref object of OpenApiRestCall_605589
proc url_RemoveTags_606386(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_RemoveTags_606385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606387 = header.getOrDefault("X-Amz-Target")
  valid_606387 = validateParameter(valid_606387, JString, required = true, default = newJString(
      "DataPipeline.RemoveTags"))
  if valid_606387 != nil:
    section.add "X-Amz-Target", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_RemoveTags_606384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes existing tags from the specified pipeline.
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_RemoveTags_606384; body: JsonNode): Recallable =
  ## removeTags
  ## Removes existing tags from the specified pipeline.
  ##   body: JObject (required)
  var body_606398 = newJObject()
  if body != nil:
    body_606398 = body
  result = call_606397.call(nil, nil, nil, nil, body_606398)

var removeTags* = Call_RemoveTags_606384(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.RemoveTags",
                                      validator: validate_RemoveTags_606385,
                                      base: "/", url: url_RemoveTags_606386,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskProgress_606399 = ref object of OpenApiRestCall_605589
proc url_ReportTaskProgress_606401(protocol: Scheme; host: string; base: string;
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

proc validate_ReportTaskProgress_606400(path: JsonNode; query: JsonNode;
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
  var valid_606402 = header.getOrDefault("X-Amz-Target")
  valid_606402 = validateParameter(valid_606402, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskProgress"))
  if valid_606402 != nil:
    section.add "X-Amz-Target", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Signature")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Signature", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Content-Sha256", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Date")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Date", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Credential")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Credential", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Security-Token")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Security-Token", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Algorithm")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Algorithm", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-SignedHeaders", valid_606409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606411: Call_ReportTaskProgress_606399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ## 
  let valid = call_606411.validator(path, query, header, formData, body)
  let scheme = call_606411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606411.url(scheme.get, call_606411.host, call_606411.base,
                         call_606411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606411, url, valid)

proc call*(call_606412: Call_ReportTaskProgress_606399; body: JsonNode): Recallable =
  ## reportTaskProgress
  ## <p>Task runners call <code>ReportTaskProgress</code> when assigned a task to acknowledge that it has the task. If the web service does not receive this acknowledgement within 2 minutes, it assigns the task in a subsequent <a>PollForTask</a> call. After this initial acknowledgement, the task runner only needs to report progress every 15 minutes to maintain its ownership of the task. You can change this reporting time from 15 minutes by specifying a <code>reportProgressTimeout</code> field in your pipeline.</p> <p>If a task runner does not report its status after 5 minutes, AWS Data Pipeline assumes that the task runner is unable to process the task and reassigns the task in a subsequent response to <a>PollForTask</a>. Task runners should call <code>ReportTaskProgress</code> every 60 seconds.</p>
  ##   body: JObject (required)
  var body_606413 = newJObject()
  if body != nil:
    body_606413 = body
  result = call_606412.call(nil, nil, nil, nil, body_606413)

var reportTaskProgress* = Call_ReportTaskProgress_606399(
    name: "reportTaskProgress", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskProgress",
    validator: validate_ReportTaskProgress_606400, base: "/",
    url: url_ReportTaskProgress_606401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReportTaskRunnerHeartbeat_606414 = ref object of OpenApiRestCall_605589
proc url_ReportTaskRunnerHeartbeat_606416(protocol: Scheme; host: string;
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

proc validate_ReportTaskRunnerHeartbeat_606415(path: JsonNode; query: JsonNode;
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
  var valid_606417 = header.getOrDefault("X-Amz-Target")
  valid_606417 = validateParameter(valid_606417, JString, required = true, default = newJString(
      "DataPipeline.ReportTaskRunnerHeartbeat"))
  if valid_606417 != nil:
    section.add "X-Amz-Target", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Signature")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Signature", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Content-Sha256", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Date")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Date", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Credential")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Credential", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Security-Token")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Security-Token", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Algorithm")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Algorithm", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-SignedHeaders", valid_606424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606426: Call_ReportTaskRunnerHeartbeat_606414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ## 
  let valid = call_606426.validator(path, query, header, formData, body)
  let scheme = call_606426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606426.url(scheme.get, call_606426.host, call_606426.base,
                         call_606426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606426, url, valid)

proc call*(call_606427: Call_ReportTaskRunnerHeartbeat_606414; body: JsonNode): Recallable =
  ## reportTaskRunnerHeartbeat
  ## Task runners call <code>ReportTaskRunnerHeartbeat</code> every 15 minutes to indicate that they are operational. If the AWS Data Pipeline Task Runner is launched on a resource managed by AWS Data Pipeline, the web service can use this call to detect when the task runner application has failed and restart a new instance.
  ##   body: JObject (required)
  var body_606428 = newJObject()
  if body != nil:
    body_606428 = body
  result = call_606427.call(nil, nil, nil, nil, body_606428)

var reportTaskRunnerHeartbeat* = Call_ReportTaskRunnerHeartbeat_606414(
    name: "reportTaskRunnerHeartbeat", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ReportTaskRunnerHeartbeat",
    validator: validate_ReportTaskRunnerHeartbeat_606415, base: "/",
    url: url_ReportTaskRunnerHeartbeat_606416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetStatus_606429 = ref object of OpenApiRestCall_605589
proc url_SetStatus_606431(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SetStatus_606430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606432 = header.getOrDefault("X-Amz-Target")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = newJString("DataPipeline.SetStatus"))
  if valid_606432 != nil:
    section.add "X-Amz-Target", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Signature")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Signature", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Content-Sha256", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Date")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Date", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Credential")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Credential", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Security-Token")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Security-Token", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Algorithm")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Algorithm", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-SignedHeaders", valid_606439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606441: Call_SetStatus_606429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ## 
  let valid = call_606441.validator(path, query, header, formData, body)
  let scheme = call_606441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606441.url(scheme.get, call_606441.host, call_606441.base,
                         call_606441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606441, url, valid)

proc call*(call_606442: Call_SetStatus_606429; body: JsonNode): Recallable =
  ## setStatus
  ## Requests that the status of the specified physical or logical pipeline objects be updated in the specified pipeline. This update might not occur immediately, but is eventually consistent. The status that can be set depends on the type of object (for example, DataNode or Activity). You cannot perform this operation on <code>FINISHED</code> pipelines and attempting to do so returns <code>InvalidRequestException</code>.
  ##   body: JObject (required)
  var body_606443 = newJObject()
  if body != nil:
    body_606443 = body
  result = call_606442.call(nil, nil, nil, nil, body_606443)

var setStatus* = Call_SetStatus_606429(name: "setStatus", meth: HttpMethod.HttpPost,
                                    host: "datapipeline.amazonaws.com", route: "/#X-Amz-Target=DataPipeline.SetStatus",
                                    validator: validate_SetStatus_606430,
                                    base: "/", url: url_SetStatus_606431,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTaskStatus_606444 = ref object of OpenApiRestCall_605589
proc url_SetTaskStatus_606446(protocol: Scheme; host: string; base: string;
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

proc validate_SetTaskStatus_606445(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606447 = header.getOrDefault("X-Amz-Target")
  valid_606447 = validateParameter(valid_606447, JString, required = true, default = newJString(
      "DataPipeline.SetTaskStatus"))
  if valid_606447 != nil:
    section.add "X-Amz-Target", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Signature")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Signature", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Content-Sha256", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Date")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Date", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Credential")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Credential", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Security-Token")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Security-Token", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Algorithm")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Algorithm", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-SignedHeaders", valid_606454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606456: Call_SetTaskStatus_606444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ## 
  let valid = call_606456.validator(path, query, header, formData, body)
  let scheme = call_606456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606456.url(scheme.get, call_606456.host, call_606456.base,
                         call_606456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606456, url, valid)

proc call*(call_606457: Call_SetTaskStatus_606444; body: JsonNode): Recallable =
  ## setTaskStatus
  ## Task runners call <code>SetTaskStatus</code> to notify AWS Data Pipeline that a task is completed and provide information about the final status. A task runner makes this call regardless of whether the task was sucessful. A task runner does not need to call <code>SetTaskStatus</code> for tasks that are canceled by the web service during a call to <a>ReportTaskProgress</a>.
  ##   body: JObject (required)
  var body_606458 = newJObject()
  if body != nil:
    body_606458 = body
  result = call_606457.call(nil, nil, nil, nil, body_606458)

var setTaskStatus* = Call_SetTaskStatus_606444(name: "setTaskStatus",
    meth: HttpMethod.HttpPost, host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.SetTaskStatus",
    validator: validate_SetTaskStatus_606445, base: "/", url: url_SetTaskStatus_606446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidatePipelineDefinition_606459 = ref object of OpenApiRestCall_605589
proc url_ValidatePipelineDefinition_606461(protocol: Scheme; host: string;
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

proc validate_ValidatePipelineDefinition_606460(path: JsonNode; query: JsonNode;
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
  var valid_606462 = header.getOrDefault("X-Amz-Target")
  valid_606462 = validateParameter(valid_606462, JString, required = true, default = newJString(
      "DataPipeline.ValidatePipelineDefinition"))
  if valid_606462 != nil:
    section.add "X-Amz-Target", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Signature")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Signature", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Content-Sha256", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Date")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Date", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Credential")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Credential", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606471: Call_ValidatePipelineDefinition_606459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ## 
  let valid = call_606471.validator(path, query, header, formData, body)
  let scheme = call_606471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606471.url(scheme.get, call_606471.host, call_606471.base,
                         call_606471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606471, url, valid)

proc call*(call_606472: Call_ValidatePipelineDefinition_606459; body: JsonNode): Recallable =
  ## validatePipelineDefinition
  ## Validates the specified pipeline definition to ensure that it is well formed and can be run without error.
  ##   body: JObject (required)
  var body_606473 = newJObject()
  if body != nil:
    body_606473 = body
  result = call_606472.call(nil, nil, nil, nil, body_606473)

var validatePipelineDefinition* = Call_ValidatePipelineDefinition_606459(
    name: "validatePipelineDefinition", meth: HttpMethod.HttpPost,
    host: "datapipeline.amazonaws.com",
    route: "/#X-Amz-Target=DataPipeline.ValidatePipelineDefinition",
    validator: validate_ValidatePipelineDefinition_606460, base: "/",
    url: url_ValidatePipelineDefinition_606461,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
