
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Analytics
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS IoT Analytics allows you to collect large amounts of device data, process messages, and store them. You can then query the data and run sophisticated analytics on it. AWS IoT Analytics enables advanced data exploration through integration with Jupyter Notebooks and data visualization through integration with Amazon QuickSight.</p> <p>Traditional analytics and business intelligence tools are designed to process structured data. IoT data often comes from devices that record noisy processes (such as temperature, motion, or sound). As a result the data from these devices can have significant gaps, corrupted messages, and false readings that must be cleaned up before analysis can occur. Also, IoT data is often only meaningful in the context of other data from external sources. </p> <p>AWS IoT Analytics automates the steps required to analyze data from IoT devices. AWS IoT Analytics filters, transforms, and enriches IoT data before storing it in a time-series data store for analysis. You can set up the service to collect only the data you need from your devices, apply mathematical transforms to process the data, and enrich the data with device-specific metadata such as device type and location before storing it. Then, you can analyze your data by running queries using the built-in SQL query engine, or perform more complex analytics and machine learning inference. AWS IoT Analytics includes pre-built models for common IoT use cases so you can answer questions like which devices are about to fail or which customers are at risk of abandoning their wearable devices.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotanalytics/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "iotanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotanalytics.ap-southeast-1.amazonaws.com",
                           "us-west-2": "iotanalytics.us-west-2.amazonaws.com",
                           "eu-west-2": "iotanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "iotanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "iotanalytics.eu-central-1.amazonaws.com",
                           "us-east-2": "iotanalytics.us-east-2.amazonaws.com",
                           "us-east-1": "iotanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "iotanalytics.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "iotanalytics.ap-south-1.amazonaws.com", "eu-north-1": "iotanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "iotanalytics.ap-northeast-2.amazonaws.com",
                           "us-west-1": "iotanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "iotanalytics.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "iotanalytics.eu-west-3.amazonaws.com", "cn-north-1": "iotanalytics.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "iotanalytics.sa-east-1.amazonaws.com",
                           "eu-west-1": "iotanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "iotanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "iotanalytics.ap-southeast-2.amazonaws.com", "ca-central-1": "iotanalytics.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "iotanalytics.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "iotanalytics.ap-southeast-1.amazonaws.com",
      "us-west-2": "iotanalytics.us-west-2.amazonaws.com",
      "eu-west-2": "iotanalytics.eu-west-2.amazonaws.com",
      "ap-northeast-3": "iotanalytics.ap-northeast-3.amazonaws.com",
      "eu-central-1": "iotanalytics.eu-central-1.amazonaws.com",
      "us-east-2": "iotanalytics.us-east-2.amazonaws.com",
      "us-east-1": "iotanalytics.us-east-1.amazonaws.com",
      "cn-northwest-1": "iotanalytics.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "iotanalytics.ap-south-1.amazonaws.com",
      "eu-north-1": "iotanalytics.eu-north-1.amazonaws.com",
      "ap-northeast-2": "iotanalytics.ap-northeast-2.amazonaws.com",
      "us-west-1": "iotanalytics.us-west-1.amazonaws.com",
      "us-gov-east-1": "iotanalytics.us-gov-east-1.amazonaws.com",
      "eu-west-3": "iotanalytics.eu-west-3.amazonaws.com",
      "cn-north-1": "iotanalytics.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "iotanalytics.sa-east-1.amazonaws.com",
      "eu-west-1": "iotanalytics.eu-west-1.amazonaws.com",
      "us-gov-west-1": "iotanalytics.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "iotanalytics.ap-southeast-2.amazonaws.com",
      "ca-central-1": "iotanalytics.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotanalytics"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_602803 = ref object of OpenApiRestCall_602466
proc url_BatchPutMessage_602805(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchPutMessage_602804(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Sends messages to a channel.
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
  var valid_602919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Content-Sha256", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Algorithm")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Algorithm", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Signature")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Signature", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-SignedHeaders", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Credential")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Credential", valid_602923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602947: Call_BatchPutMessage_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_602947.validator(path, query, header, formData, body)
  let scheme = call_602947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602947.url(scheme.get, call_602947.host, call_602947.base,
                         call_602947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602947, url, valid)

proc call*(call_603018: Call_BatchPutMessage_602803; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_603019 = newJObject()
  if body != nil:
    body_603019 = body
  result = call_603018.call(nil, nil, nil, nil, body_603019)

var batchPutMessage* = Call_BatchPutMessage_602803(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_602804, base: "/",
    url: url_BatchPutMessage_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_603058 = ref object of OpenApiRestCall_602466
proc url_CancelPipelineReprocessing_603060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  assert "reprocessingId" in path, "`reprocessingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName"),
               (kind: ConstantSegment, value: "/reprocessing/"),
               (kind: VariableSegment, value: "reprocessingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CancelPipelineReprocessing_603059(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reprocessingId: JString (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: JString (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reprocessingId` field"
  var valid_603075 = path.getOrDefault("reprocessingId")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = nil)
  if valid_603075 != nil:
    section.add "reprocessingId", valid_603075
  var valid_603076 = path.getOrDefault("pipelineName")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "pipelineName", valid_603076
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603077 = header.getOrDefault("X-Amz-Date")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Date", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Security-Token")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Security-Token", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-SignedHeaders", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CancelPipelineReprocessing_603058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CancelPipelineReprocessing_603058;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_603086 = newJObject()
  add(path_603086, "reprocessingId", newJString(reprocessingId))
  add(path_603086, "pipelineName", newJString(pipelineName))
  result = call_603085.call(path_603086, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_603058(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_603059, base: "/",
    url: url_CancelPipelineReprocessing_603060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_603103 = ref object of OpenApiRestCall_602466
proc url_CreateChannel_603105(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateChannel_603104(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603106 = header.getOrDefault("X-Amz-Date")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Date", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Security-Token")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Security-Token", valid_603107
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

proc call*(call_603114: Call_CreateChannel_603103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateChannel_603103; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createChannel* = Call_CreateChannel_603103(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_603104, base: "/",
    url: url_CreateChannel_603105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_603088 = ref object of OpenApiRestCall_602466
proc url_ListChannels_603090(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChannels_603089(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of channels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_603091 = query.getOrDefault("maxResults")
  valid_603091 = validateParameter(valid_603091, JInt, required = false, default = nil)
  if valid_603091 != nil:
    section.add "maxResults", valid_603091
  var valid_603092 = query.getOrDefault("nextToken")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "nextToken", valid_603092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603093 = header.getOrDefault("X-Amz-Date")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Date", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Security-Token")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Security-Token", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Content-Sha256", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Algorithm")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Algorithm", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Signature")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Signature", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-SignedHeaders", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Credential")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Credential", valid_603099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603100: Call_ListChannels_603088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_603100.validator(path, query, header, formData, body)
  let scheme = call_603100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603100.url(scheme.get, call_603100.host, call_603100.base,
                         call_603100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603100, url, valid)

proc call*(call_603101: Call_ListChannels_603088; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_603102 = newJObject()
  add(query_603102, "maxResults", newJInt(maxResults))
  add(query_603102, "nextToken", newJString(nextToken))
  result = call_603101.call(nil, query_603102, nil, nil, nil)

var listChannels* = Call_ListChannels_603088(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_603089, base: "/",
    url: url_ListChannels_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_603132 = ref object of OpenApiRestCall_602466
proc url_CreateDataset_603134(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataset_603133(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
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
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Signature")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Signature", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Credential")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Credential", valid_603141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603143: Call_CreateDataset_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_603143.validator(path, query, header, formData, body)
  let scheme = call_603143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603143.url(scheme.get, call_603143.host, call_603143.base,
                         call_603143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603143, url, valid)

proc call*(call_603144: Call_CreateDataset_603132; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_603145 = newJObject()
  if body != nil:
    body_603145 = body
  result = call_603144.call(nil, nil, nil, nil, body_603145)

var createDataset* = Call_CreateDataset_603132(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_603133, base: "/",
    url: url_CreateDataset_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_603117 = ref object of OpenApiRestCall_602466
proc url_ListDatasets_603119(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatasets_603118(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about data sets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_603120 = query.getOrDefault("maxResults")
  valid_603120 = validateParameter(valid_603120, JInt, required = false, default = nil)
  if valid_603120 != nil:
    section.add "maxResults", valid_603120
  var valid_603121 = query.getOrDefault("nextToken")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "nextToken", valid_603121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603122 = header.getOrDefault("X-Amz-Date")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Date", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Security-Token")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Security-Token", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_ListDatasets_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_ListDatasets_603117; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_603131 = newJObject()
  add(query_603131, "maxResults", newJInt(maxResults))
  add(query_603131, "nextToken", newJString(nextToken))
  result = call_603130.call(nil, query_603131, nil, nil, nil)

var listDatasets* = Call_ListDatasets_603117(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_603118, base: "/",
    url: url_ListDatasets_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_603162 = ref object of OpenApiRestCall_602466
proc url_CreateDatasetContent_603164(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateDatasetContent_603163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603165 = path.getOrDefault("datasetName")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = nil)
  if valid_603165 != nil:
    section.add "datasetName", valid_603165
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603166 = header.getOrDefault("X-Amz-Date")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Date", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
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
  if body != nil:
    result.add "body", body

proc call*(call_603173: Call_CreateDatasetContent_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_603173.validator(path, query, header, formData, body)
  let scheme = call_603173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603173.url(scheme.get, call_603173.host, call_603173.base,
                         call_603173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603173, url, valid)

proc call*(call_603174: Call_CreateDatasetContent_603162; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_603175 = newJObject()
  add(path_603175, "datasetName", newJString(datasetName))
  result = call_603174.call(path_603175, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_603162(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_603163, base: "/",
    url: url_CreateDatasetContent_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_603146 = ref object of OpenApiRestCall_602466
proc url_GetDatasetContent_603148(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDatasetContent_603147(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set whose contents are retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603149 = path.getOrDefault("datasetName")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = nil)
  if valid_603149 != nil:
    section.add "datasetName", valid_603149
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_603150 = query.getOrDefault("versionId")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "versionId", valid_603150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
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
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_GetDatasetContent_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603158, url, valid)

proc call*(call_603159: Call_GetDatasetContent_603146; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_603160 = newJObject()
  var query_603161 = newJObject()
  add(query_603161, "versionId", newJString(versionId))
  add(path_603160, "datasetName", newJString(datasetName))
  result = call_603159.call(path_603160, query_603161, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_603146(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_603147, base: "/",
    url: url_GetDatasetContent_603148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_603176 = ref object of OpenApiRestCall_602466
proc url_DeleteDatasetContent_603178(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDatasetContent_603177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the content of the specified data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set whose content is deleted.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603179 = path.getOrDefault("datasetName")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = nil)
  if valid_603179 != nil:
    section.add "datasetName", valid_603179
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_603180 = query.getOrDefault("versionId")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "versionId", valid_603180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603181 = header.getOrDefault("X-Amz-Date")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Date", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Security-Token")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Security-Token", valid_603182
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
  if body != nil:
    result.add "body", body

proc call*(call_603188: Call_DeleteDatasetContent_603176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_603188.validator(path, query, header, formData, body)
  let scheme = call_603188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603188.url(scheme.get, call_603188.host, call_603188.base,
                         call_603188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603188, url, valid)

proc call*(call_603189: Call_DeleteDatasetContent_603176; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_603190 = newJObject()
  var query_603191 = newJObject()
  add(query_603191, "versionId", newJString(versionId))
  add(path_603190, "datasetName", newJString(datasetName))
  result = call_603189.call(path_603190, query_603191, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_603176(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_603177, base: "/",
    url: url_DeleteDatasetContent_603178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_603207 = ref object of OpenApiRestCall_602466
proc url_CreateDatastore_603209(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatastore_603208(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a data store, which is a repository for messages.
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
  var valid_603212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Content-Sha256", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Algorithm")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Algorithm", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Signature")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Signature", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-SignedHeaders", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Credential")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Credential", valid_603216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603218: Call_CreateDatastore_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_603218.validator(path, query, header, formData, body)
  let scheme = call_603218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603218.url(scheme.get, call_603218.host, call_603218.base,
                         call_603218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603218, url, valid)

proc call*(call_603219: Call_CreateDatastore_603207; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_603220 = newJObject()
  if body != nil:
    body_603220 = body
  result = call_603219.call(nil, nil, nil, nil, body_603220)

var createDatastore* = Call_CreateDatastore_603207(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_603208, base: "/",
    url: url_CreateDatastore_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_603192 = ref object of OpenApiRestCall_602466
proc url_ListDatastores_603194(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatastores_603193(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of data stores.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_603195 = query.getOrDefault("maxResults")
  valid_603195 = validateParameter(valid_603195, JInt, required = false, default = nil)
  if valid_603195 != nil:
    section.add "maxResults", valid_603195
  var valid_603196 = query.getOrDefault("nextToken")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "nextToken", valid_603196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603197 = header.getOrDefault("X-Amz-Date")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Date", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Security-Token")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Security-Token", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_ListDatastores_603192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_ListDatastores_603192; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_603206 = newJObject()
  add(query_603206, "maxResults", newJInt(maxResults))
  add(query_603206, "nextToken", newJString(nextToken))
  result = call_603205.call(nil, query_603206, nil, nil, nil)

var listDatastores* = Call_ListDatastores_603192(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_603193, base: "/",
    url: url_ListDatastores_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_603236 = ref object of OpenApiRestCall_602466
proc url_CreatePipeline_603238(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_603237(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a pipeline. A pipeline consumes messages from one or more channels and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Credential")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Credential", valid_603245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603247: Call_CreatePipeline_603236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from one or more channels and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_603247.validator(path, query, header, formData, body)
  let scheme = call_603247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603247.url(scheme.get, call_603247.host, call_603247.base,
                         call_603247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603247, url, valid)

proc call*(call_603248: Call_CreatePipeline_603236; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from one or more channels and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_603249 = newJObject()
  if body != nil:
    body_603249 = body
  result = call_603248.call(nil, nil, nil, nil, body_603249)

var createPipeline* = Call_CreatePipeline_603236(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_603237, base: "/",
    url: url_CreatePipeline_603238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_603221 = ref object of OpenApiRestCall_602466
proc url_ListPipelines_603223(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_603222(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of pipelines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_603224 = query.getOrDefault("maxResults")
  valid_603224 = validateParameter(valid_603224, JInt, required = false, default = nil)
  if valid_603224 != nil:
    section.add "maxResults", valid_603224
  var valid_603225 = query.getOrDefault("nextToken")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "nextToken", valid_603225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603226 = header.getOrDefault("X-Amz-Date")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Date", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Security-Token")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Security-Token", valid_603227
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
  if body != nil:
    result.add "body", body

proc call*(call_603233: Call_ListPipelines_603221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_603233.validator(path, query, header, formData, body)
  let scheme = call_603233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603233.url(scheme.get, call_603233.host, call_603233.base,
                         call_603233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603233, url, valid)

proc call*(call_603234: Call_ListPipelines_603221; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_603235 = newJObject()
  add(query_603235, "maxResults", newJInt(maxResults))
  add(query_603235, "nextToken", newJString(nextToken))
  result = call_603234.call(nil, query_603235, nil, nil, nil)

var listPipelines* = Call_ListPipelines_603221(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_603222, base: "/",
    url: url_ListPipelines_603223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_603266 = ref object of OpenApiRestCall_602466
proc url_UpdateChannel_603268(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateChannel_603267(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings of a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelName: JString (required)
  ##              : The name of the channel to be updated.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `channelName` field"
  var valid_603269 = path.getOrDefault("channelName")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "channelName", valid_603269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Content-Sha256", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Algorithm")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Algorithm", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Signature")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Signature", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-SignedHeaders", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Credential")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Credential", valid_603276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603278: Call_UpdateChannel_603266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_603278.validator(path, query, header, formData, body)
  let scheme = call_603278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603278.url(scheme.get, call_603278.host, call_603278.base,
                         call_603278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603278, url, valid)

proc call*(call_603279: Call_UpdateChannel_603266; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_603280 = newJObject()
  var body_603281 = newJObject()
  add(path_603280, "channelName", newJString(channelName))
  if body != nil:
    body_603281 = body
  result = call_603279.call(path_603280, nil, nil, nil, body_603281)

var updateChannel* = Call_UpdateChannel_603266(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_603267,
    base: "/", url: url_UpdateChannel_603268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_603250 = ref object of OpenApiRestCall_602466
proc url_DescribeChannel_603252(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeChannel_603251(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves information about a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelName: JString (required)
  ##              : The name of the channel whose information is retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `channelName` field"
  var valid_603253 = path.getOrDefault("channelName")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "channelName", valid_603253
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response.
  section = newJObject()
  var valid_603254 = query.getOrDefault("includeStatistics")
  valid_603254 = validateParameter(valid_603254, JBool, required = false, default = nil)
  if valid_603254 != nil:
    section.add "includeStatistics", valid_603254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Content-Sha256", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Signature")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Signature", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603262: Call_DescribeChannel_603250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_603262.validator(path, query, header, formData, body)
  let scheme = call_603262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603262.url(scheme.get, call_603262.host, call_603262.base,
                         call_603262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603262, url, valid)

proc call*(call_603263: Call_DescribeChannel_603250; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response.
  var path_603264 = newJObject()
  var query_603265 = newJObject()
  add(path_603264, "channelName", newJString(channelName))
  add(query_603265, "includeStatistics", newJBool(includeStatistics))
  result = call_603263.call(path_603264, query_603265, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_603250(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_603251,
    base: "/", url: url_DescribeChannel_603252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_603282 = ref object of OpenApiRestCall_602466
proc url_DeleteChannel_603284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteChannel_603283(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelName: JString (required)
  ##              : The name of the channel to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `channelName` field"
  var valid_603285 = path.getOrDefault("channelName")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = nil)
  if valid_603285 != nil:
    section.add "channelName", valid_603285
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_DeleteChannel_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603293, url, valid)

proc call*(call_603294: Call_DeleteChannel_603282; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_603295 = newJObject()
  add(path_603295, "channelName", newJString(channelName))
  result = call_603294.call(path_603295, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_603282(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_603283,
    base: "/", url: url_DeleteChannel_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_603310 = ref object of OpenApiRestCall_602466
proc url_UpdateDataset_603312(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDataset_603311(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings of a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603313 = path.getOrDefault("datasetName")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = nil)
  if valid_603313 != nil:
    section.add "datasetName", valid_603313
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603314 = header.getOrDefault("X-Amz-Date")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Date", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Security-Token")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Security-Token", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Content-Sha256", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Algorithm")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Algorithm", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Signature")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Signature", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-SignedHeaders", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Credential")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Credential", valid_603320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603322: Call_UpdateDataset_603310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_603322.validator(path, query, header, formData, body)
  let scheme = call_603322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603322.url(scheme.get, call_603322.host, call_603322.base,
                         call_603322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603322, url, valid)

proc call*(call_603323: Call_UpdateDataset_603310; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_603324 = newJObject()
  var body_603325 = newJObject()
  add(path_603324, "datasetName", newJString(datasetName))
  if body != nil:
    body_603325 = body
  result = call_603323.call(path_603324, nil, nil, nil, body_603325)

var updateDataset* = Call_UpdateDataset_603310(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_603311,
    base: "/", url: url_UpdateDataset_603312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_603296 = ref object of OpenApiRestCall_602466
proc url_DescribeDataset_603298(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeDataset_603297(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set whose information is retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603299 = path.getOrDefault("datasetName")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "datasetName", valid_603299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Content-Sha256", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Algorithm")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Algorithm", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Signature")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Signature", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-SignedHeaders", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Credential")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Credential", valid_603306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603307: Call_DescribeDataset_603296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_603307.validator(path, query, header, formData, body)
  let scheme = call_603307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603307.url(scheme.get, call_603307.host, call_603307.base,
                         call_603307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603307, url, valid)

proc call*(call_603308: Call_DescribeDataset_603296; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_603309 = newJObject()
  add(path_603309, "datasetName", newJString(datasetName))
  result = call_603308.call(path_603309, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_603296(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_603297,
    base: "/", url: url_DescribeDataset_603298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_603326 = ref object of OpenApiRestCall_602466
proc url_DeleteDataset_603328(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDataset_603327(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603329 = path.getOrDefault("datasetName")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = nil)
  if valid_603329 != nil:
    section.add "datasetName", valid_603329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Content-Sha256", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Algorithm")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Algorithm", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Signature")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Signature", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-SignedHeaders", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Credential")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Credential", valid_603336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603337: Call_DeleteDataset_603326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_603337.validator(path, query, header, formData, body)
  let scheme = call_603337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603337.url(scheme.get, call_603337.host, call_603337.base,
                         call_603337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603337, url, valid)

proc call*(call_603338: Call_DeleteDataset_603326; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_603339 = newJObject()
  add(path_603339, "datasetName", newJString(datasetName))
  result = call_603338.call(path_603339, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_603326(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_603327,
    base: "/", url: url_DeleteDataset_603328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_603356 = ref object of OpenApiRestCall_602466
proc url_UpdateDatastore_603358(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDatastore_603357(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the settings of a data store.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datastoreName: JString (required)
  ##                : The name of the data store to be updated.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datastoreName` field"
  var valid_603359 = path.getOrDefault("datastoreName")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = nil)
  if valid_603359 != nil:
    section.add "datastoreName", valid_603359
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Content-Sha256", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Algorithm")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Algorithm", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Signature")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Signature", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-SignedHeaders", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Credential")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Credential", valid_603366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603368: Call_UpdateDatastore_603356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_603368.validator(path, query, header, formData, body)
  let scheme = call_603368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603368.url(scheme.get, call_603368.host, call_603368.base,
                         call_603368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603368, url, valid)

proc call*(call_603369: Call_UpdateDatastore_603356; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_603370 = newJObject()
  var body_603371 = newJObject()
  add(path_603370, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_603371 = body
  result = call_603369.call(path_603370, nil, nil, nil, body_603371)

var updateDatastore* = Call_UpdateDatastore_603356(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_603357,
    base: "/", url: url_UpdateDatastore_603358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_603340 = ref object of OpenApiRestCall_602466
proc url_DescribeDatastore_603342(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeDatastore_603341(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves information about a data store.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datastoreName: JString (required)
  ##                : The name of the data store
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datastoreName` field"
  var valid_603343 = path.getOrDefault("datastoreName")
  valid_603343 = validateParameter(valid_603343, JString, required = true,
                                 default = nil)
  if valid_603343 != nil:
    section.add "datastoreName", valid_603343
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the datastore is included in the response.
  section = newJObject()
  var valid_603344 = query.getOrDefault("includeStatistics")
  valid_603344 = validateParameter(valid_603344, JBool, required = false, default = nil)
  if valid_603344 != nil:
    section.add "includeStatistics", valid_603344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Content-Sha256", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Algorithm")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Algorithm", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Signature")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Signature", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-SignedHeaders", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_DescribeDatastore_603340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_DescribeDatastore_603340; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the datastore is included in the response.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  var path_603354 = newJObject()
  var query_603355 = newJObject()
  add(query_603355, "includeStatistics", newJBool(includeStatistics))
  add(path_603354, "datastoreName", newJString(datastoreName))
  result = call_603353.call(path_603354, query_603355, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_603340(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_603341,
    base: "/", url: url_DescribeDatastore_603342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_603372 = ref object of OpenApiRestCall_602466
proc url_DeleteDatastore_603374(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDatastore_603373(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes the specified data store.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datastoreName: JString (required)
  ##                : The name of the data store to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datastoreName` field"
  var valid_603375 = path.getOrDefault("datastoreName")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = nil)
  if valid_603375 != nil:
    section.add "datastoreName", valid_603375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603383: Call_DeleteDatastore_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_603383.validator(path, query, header, formData, body)
  let scheme = call_603383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603383.url(scheme.get, call_603383.host, call_603383.base,
                         call_603383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603383, url, valid)

proc call*(call_603384: Call_DeleteDatastore_603372; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_603385 = newJObject()
  add(path_603385, "datastoreName", newJString(datastoreName))
  result = call_603384.call(path_603385, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_603372(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_603373,
    base: "/", url: url_DeleteDatastore_603374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_603400 = ref object of OpenApiRestCall_602466
proc url_UpdatePipeline_603402(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdatePipeline_603401(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   pipelineName: JString (required)
  ##               : The name of the pipeline to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `pipelineName` field"
  var valid_603403 = path.getOrDefault("pipelineName")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = nil)
  if valid_603403 != nil:
    section.add "pipelineName", valid_603403
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603404 = header.getOrDefault("X-Amz-Date")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Date", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Security-Token")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Security-Token", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Content-Sha256", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Algorithm")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Algorithm", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Signature")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Signature", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-SignedHeaders", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Credential")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Credential", valid_603410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_UpdatePipeline_603400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_UpdatePipeline_603400; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_603414 = newJObject()
  var body_603415 = newJObject()
  add(path_603414, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_603415 = body
  result = call_603413.call(path_603414, nil, nil, nil, body_603415)

var updatePipeline* = Call_UpdatePipeline_603400(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_603401,
    base: "/", url: url_UpdatePipeline_603402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_603386 = ref object of OpenApiRestCall_602466
proc url_DescribePipeline_603388(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribePipeline_603387(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves information about a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   pipelineName: JString (required)
  ##               : The name of the pipeline whose information is retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `pipelineName` field"
  var valid_603389 = path.getOrDefault("pipelineName")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = nil)
  if valid_603389 != nil:
    section.add "pipelineName", valid_603389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Algorithm")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Algorithm", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Signature")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Signature", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-SignedHeaders", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Credential")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Credential", valid_603396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_DescribePipeline_603386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_DescribePipeline_603386; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_603399 = newJObject()
  add(path_603399, "pipelineName", newJString(pipelineName))
  result = call_603398.call(path_603399, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_603386(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_603387,
    base: "/", url: url_DescribePipeline_603388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_603416 = ref object of OpenApiRestCall_602466
proc url_DeletePipeline_603418(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeletePipeline_603417(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   pipelineName: JString (required)
  ##               : The name of the pipeline to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `pipelineName` field"
  var valid_603419 = path.getOrDefault("pipelineName")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "pipelineName", valid_603419
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Content-Sha256", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Algorithm")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Algorithm", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Signature")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Signature", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-SignedHeaders", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Credential")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Credential", valid_603426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603427: Call_DeletePipeline_603416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_603427.validator(path, query, header, formData, body)
  let scheme = call_603427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603427.url(scheme.get, call_603427.host, call_603427.base,
                         call_603427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603427, url, valid)

proc call*(call_603428: Call_DeletePipeline_603416; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_603429 = newJObject()
  add(path_603429, "pipelineName", newJString(pipelineName))
  result = call_603428.call(path_603429, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_603416(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_603417,
    base: "/", url: url_DeletePipeline_603418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_603442 = ref object of OpenApiRestCall_602466
proc url_PutLoggingOptions_603444(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLoggingOptions_603443(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603445 = header.getOrDefault("X-Amz-Date")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Date", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Security-Token")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Security-Token", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Content-Sha256", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Algorithm")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Algorithm", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Signature")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Signature", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-SignedHeaders", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Credential")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Credential", valid_603451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603453: Call_PutLoggingOptions_603442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_603453.validator(path, query, header, formData, body)
  let scheme = call_603453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603453.url(scheme.get, call_603453.host, call_603453.base,
                         call_603453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603453, url, valid)

proc call*(call_603454: Call_PutLoggingOptions_603442; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_603455 = newJObject()
  if body != nil:
    body_603455 = body
  result = call_603454.call(nil, nil, nil, nil, body_603455)

var putLoggingOptions* = Call_PutLoggingOptions_603442(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_603443, base: "/",
    url: url_PutLoggingOptions_603444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_603430 = ref object of OpenApiRestCall_602466
proc url_DescribeLoggingOptions_603432(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLoggingOptions_603431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Credential")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Credential", valid_603439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603440: Call_DescribeLoggingOptions_603430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_603440.validator(path, query, header, formData, body)
  let scheme = call_603440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603440.url(scheme.get, call_603440.host, call_603440.base,
                         call_603440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603440, url, valid)

proc call*(call_603441: Call_DescribeLoggingOptions_603430): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_603441.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_603430(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_603431, base: "/",
    url: url_DescribeLoggingOptions_603432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_603456 = ref object of OpenApiRestCall_602466
proc url_ListDatasetContents_603458(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDatasetContents_603457(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists information about data set contents that have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   datasetName: JString (required)
  ##              : The name of the data set whose contents information you want to list.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `datasetName` field"
  var valid_603459 = path.getOrDefault("datasetName")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = nil)
  if valid_603459 != nil:
    section.add "datasetName", valid_603459
  result.add "path", section
  ## parameters in `query` object:
  ##   scheduledOnOrAfter: JString
  ##                     : A filter to limit results to those data set contents whose creation is scheduled on or after the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   scheduledBefore: JString
  ##                  : A filter to limit results to those data set contents whose creation is scheduled before the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   maxResults: JInt
  ##             : The maximum number of results to return in this request.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_603460 = query.getOrDefault("scheduledOnOrAfter")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "scheduledOnOrAfter", valid_603460
  var valid_603461 = query.getOrDefault("scheduledBefore")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "scheduledBefore", valid_603461
  var valid_603462 = query.getOrDefault("maxResults")
  valid_603462 = validateParameter(valid_603462, JInt, required = false, default = nil)
  if valid_603462 != nil:
    section.add "maxResults", valid_603462
  var valid_603463 = query.getOrDefault("nextToken")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "nextToken", valid_603463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603464 = header.getOrDefault("X-Amz-Date")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Date", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Security-Token")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Security-Token", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Content-Sha256", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Algorithm")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Algorithm", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Signature")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Signature", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-SignedHeaders", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Credential")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Credential", valid_603470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603471: Call_ListDatasetContents_603456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_603471.validator(path, query, header, formData, body)
  let scheme = call_603471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603471.url(scheme.get, call_603471.host, call_603471.base,
                         call_603471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603471, url, valid)

proc call*(call_603472: Call_ListDatasetContents_603456; datasetName: string;
          scheduledOnOrAfter: string = ""; scheduledBefore: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDatasetContents
  ## Lists information about data set contents that have been created.
  ##   scheduledOnOrAfter: string
  ##                     : A filter to limit results to those data set contents whose creation is scheduled on or after the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   scheduledBefore: string
  ##                  : A filter to limit results to those data set contents whose creation is scheduled before the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   maxResults: int
  ##             : The maximum number of results to return in this request.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents information you want to list.
  var path_603473 = newJObject()
  var query_603474 = newJObject()
  add(query_603474, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(query_603474, "scheduledBefore", newJString(scheduledBefore))
  add(query_603474, "maxResults", newJInt(maxResults))
  add(query_603474, "nextToken", newJString(nextToken))
  add(path_603473, "datasetName", newJString(datasetName))
  result = call_603472.call(path_603473, query_603474, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_603456(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_603457, base: "/",
    url: url_ListDatasetContents_603458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603489 = ref object of OpenApiRestCall_602466
proc url_TagResource_603491(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603490(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource whose tags you want to modify.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_603492 = query.getOrDefault("resourceArn")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "resourceArn", valid_603492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603493 = header.getOrDefault("X-Amz-Date")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Date", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Security-Token")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Security-Token", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Content-Sha256", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Credential")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Credential", valid_603499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603501: Call_TagResource_603489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_603501.validator(path, query, header, formData, body)
  let scheme = call_603501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603501.url(scheme.get, call_603501.host, call_603501.base,
                         call_603501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603501, url, valid)

proc call*(call_603502: Call_TagResource_603489; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  ##   body: JObject (required)
  var query_603503 = newJObject()
  var body_603504 = newJObject()
  add(query_603503, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_603504 = body
  result = call_603502.call(nil, query_603503, nil, nil, body_603504)

var tagResource* = Call_TagResource_603489(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_603490,
                                        base: "/", url: url_TagResource_603491,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603475 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603477(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603476(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource whose tags you want to list.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_603478 = query.getOrDefault("resourceArn")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = nil)
  if valid_603478 != nil:
    section.add "resourceArn", valid_603478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603479 = header.getOrDefault("X-Amz-Date")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Date", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Security-Token")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Security-Token", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Content-Sha256", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Algorithm")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Algorithm", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Signature")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Signature", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-SignedHeaders", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Credential")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Credential", valid_603485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603486: Call_ListTagsForResource_603475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_603486.validator(path, query, header, formData, body)
  let scheme = call_603486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603486.url(scheme.get, call_603486.host, call_603486.base,
                         call_603486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603486, url, valid)

proc call*(call_603487: Call_ListTagsForResource_603475; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_603488 = newJObject()
  add(query_603488, "resourceArn", newJString(resourceArn))
  result = call_603487.call(nil, query_603488, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603475(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_603476, base: "/",
    url: url_ListTagsForResource_603477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_603505 = ref object of OpenApiRestCall_602466
proc url_RunPipelineActivity_603507(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RunPipelineActivity_603506(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Simulates the results of running a pipeline activity on a message payload.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603508 = header.getOrDefault("X-Amz-Date")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Date", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Algorithm")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Algorithm", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-SignedHeaders", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Credential")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Credential", valid_603514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603516: Call_RunPipelineActivity_603505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_603516.validator(path, query, header, formData, body)
  let scheme = call_603516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603516.url(scheme.get, call_603516.host, call_603516.base,
                         call_603516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603516, url, valid)

proc call*(call_603517: Call_RunPipelineActivity_603505; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_603518 = newJObject()
  if body != nil:
    body_603518 = body
  result = call_603517.call(nil, nil, nil, nil, body_603518)

var runPipelineActivity* = Call_RunPipelineActivity_603505(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_603506, base: "/",
    url: url_RunPipelineActivity_603507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_603519 = ref object of OpenApiRestCall_602466
proc url_SampleChannelData_603521(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName"),
               (kind: ConstantSegment, value: "/sample")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_SampleChannelData_603520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelName: JString (required)
  ##              : The name of the channel whose message samples are retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `channelName` field"
  var valid_603522 = path.getOrDefault("channelName")
  valid_603522 = validateParameter(valid_603522, JString, required = true,
                                 default = nil)
  if valid_603522 != nil:
    section.add "channelName", valid_603522
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_603523 = query.getOrDefault("endTime")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "endTime", valid_603523
  var valid_603524 = query.getOrDefault("maxMessages")
  valid_603524 = validateParameter(valid_603524, JInt, required = false, default = nil)
  if valid_603524 != nil:
    section.add "maxMessages", valid_603524
  var valid_603525 = query.getOrDefault("startTime")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "startTime", valid_603525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603526 = header.getOrDefault("X-Amz-Date")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Date", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Security-Token")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Security-Token", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_SampleChannelData_603519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603533, url, valid)

proc call*(call_603534: Call_SampleChannelData_603519; channelName: string;
          endTime: string = ""; maxMessages: int = 0; startTime: string = ""): Recallable =
  ## sampleChannelData
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ##   endTime: string
  ##          : The end of the time window from which sample messages are retrieved.
  ##   maxMessages: int
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   channelName: string (required)
  ##              : The name of the channel whose message samples are retrieved.
  ##   startTime: string
  ##            : The start of the time window from which sample messages are retrieved.
  var path_603535 = newJObject()
  var query_603536 = newJObject()
  add(query_603536, "endTime", newJString(endTime))
  add(query_603536, "maxMessages", newJInt(maxMessages))
  add(path_603535, "channelName", newJString(channelName))
  add(query_603536, "startTime", newJString(startTime))
  result = call_603534.call(path_603535, query_603536, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_603519(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_603520, base: "/",
    url: url_SampleChannelData_603521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_603537 = ref object of OpenApiRestCall_602466
proc url_StartPipelineReprocessing_603539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName"),
               (kind: ConstantSegment, value: "/reprocessing")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_StartPipelineReprocessing_603538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   pipelineName: JString (required)
  ##               : The name of the pipeline on which to start reprocessing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `pipelineName` field"
  var valid_603540 = path.getOrDefault("pipelineName")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = nil)
  if valid_603540 != nil:
    section.add "pipelineName", valid_603540
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_StartPipelineReprocessing_603537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_StartPipelineReprocessing_603537;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_603551 = newJObject()
  var body_603552 = newJObject()
  add(path_603551, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_603552 = body
  result = call_603550.call(path_603551, nil, nil, nil, body_603552)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_603537(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_603538, base: "/",
    url: url_StartPipelineReprocessing_603539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603553 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603555(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603554(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the given tags (metadata) from the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource whose tags you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_603556 = query.getOrDefault("resourceArn")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = nil)
  if valid_603556 != nil:
    section.add "resourceArn", valid_603556
  var valid_603557 = query.getOrDefault("tagKeys")
  valid_603557 = validateParameter(valid_603557, JArray, required = true, default = nil)
  if valid_603557 != nil:
    section.add "tagKeys", valid_603557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603558 = header.getOrDefault("X-Amz-Date")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Date", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Security-Token")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Security-Token", valid_603559
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
  if body != nil:
    result.add "body", body

proc call*(call_603565: Call_UntagResource_603553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_603565.validator(path, query, header, formData, body)
  let scheme = call_603565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603565.url(scheme.get, call_603565.host, call_603565.base,
                         call_603565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603565, url, valid)

proc call*(call_603566: Call_UntagResource_603553; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var query_603567 = newJObject()
  add(query_603567, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_603567.add "tagKeys", tagKeys
  result = call_603566.call(nil, query_603567, nil, nil, nil)

var untagResource* = Call_UntagResource_603553(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_603554,
    base: "/", url: url_UntagResource_603555, schemes: {Scheme.Https, Scheme.Http})
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
