
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_612996 = ref object of OpenApiRestCall_612658
proc url_BatchPutMessage_612998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchPutMessage_612997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613110 = header.getOrDefault("X-Amz-Signature")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Signature", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Content-Sha256", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Date")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Date", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Credential")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Credential", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Security-Token")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Security-Token", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Algorithm")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Algorithm", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-SignedHeaders", valid_613116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_BatchPutMessage_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_BatchPutMessage_612996; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_613212 = newJObject()
  if body != nil:
    body_613212 = body
  result = call_613211.call(nil, nil, nil, nil, body_613212)

var batchPutMessage* = Call_BatchPutMessage_612996(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_612997, base: "/",
    url: url_BatchPutMessage_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_613251 = ref object of OpenApiRestCall_612658
proc url_CancelPipelineReprocessing_613253(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelPipelineReprocessing_613252(path: JsonNode; query: JsonNode;
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
  var valid_613268 = path.getOrDefault("reprocessingId")
  valid_613268 = validateParameter(valid_613268, JString, required = true,
                                 default = nil)
  if valid_613268 != nil:
    section.add "reprocessingId", valid_613268
  var valid_613269 = path.getOrDefault("pipelineName")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "pipelineName", valid_613269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_CancelPipelineReprocessing_613251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CancelPipelineReprocessing_613251;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_613279 = newJObject()
  add(path_613279, "reprocessingId", newJString(reprocessingId))
  add(path_613279, "pipelineName", newJString(pipelineName))
  result = call_613278.call(path_613279, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_613251(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_613252, base: "/",
    url: url_CancelPipelineReprocessing_613253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_613296 = ref object of OpenApiRestCall_612658
proc url_CreateChannel_613298(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_613297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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

proc call*(call_613307: Call_CreateChannel_613296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateChannel_613296; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createChannel* = Call_CreateChannel_613296(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_613297, base: "/",
    url: url_CreateChannel_613298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_613281 = ref object of OpenApiRestCall_612658
proc url_ListChannels_613283(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_613282(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of channels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  section = newJObject()
  var valid_613284 = query.getOrDefault("nextToken")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "nextToken", valid_613284
  var valid_613285 = query.getOrDefault("maxResults")
  valid_613285 = validateParameter(valid_613285, JInt, required = false, default = nil)
  if valid_613285 != nil:
    section.add "maxResults", valid_613285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613286 = header.getOrDefault("X-Amz-Signature")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Signature", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Content-Sha256", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Date")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Date", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Credential")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Credential", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Security-Token")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Security-Token", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Algorithm")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Algorithm", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_ListChannels_613281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_ListChannels_613281; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_613295 = newJObject()
  add(query_613295, "nextToken", newJString(nextToken))
  add(query_613295, "maxResults", newJInt(maxResults))
  result = call_613294.call(nil, query_613295, nil, nil, nil)

var listChannels* = Call_ListChannels_613281(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_613282, base: "/",
    url: url_ListChannels_613283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_613325 = ref object of OpenApiRestCall_612658
proc url_CreateDataset_613327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataset_613326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Signature")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Signature", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Content-Sha256", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Date")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Date", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Credential")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Credential", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Security-Token")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Security-Token", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Algorithm")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Algorithm", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-SignedHeaders", valid_613334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613336: Call_CreateDataset_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_613336.validator(path, query, header, formData, body)
  let scheme = call_613336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613336.url(scheme.get, call_613336.host, call_613336.base,
                         call_613336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613336, url, valid)

proc call*(call_613337: Call_CreateDataset_613325; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_613338 = newJObject()
  if body != nil:
    body_613338 = body
  result = call_613337.call(nil, nil, nil, nil, body_613338)

var createDataset* = Call_CreateDataset_613325(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_613326, base: "/",
    url: url_CreateDataset_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_613310 = ref object of OpenApiRestCall_612658
proc url_ListDatasets_613312(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasets_613311(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about data sets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  section = newJObject()
  var valid_613313 = query.getOrDefault("nextToken")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "nextToken", valid_613313
  var valid_613314 = query.getOrDefault("maxResults")
  valid_613314 = validateParameter(valid_613314, JInt, required = false, default = nil)
  if valid_613314 != nil:
    section.add "maxResults", valid_613314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613315 = header.getOrDefault("X-Amz-Signature")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Signature", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Content-Sha256", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Date")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Date", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Credential")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Credential", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Security-Token")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Security-Token", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Algorithm")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Algorithm", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-SignedHeaders", valid_613321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_ListDatasets_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_ListDatasets_613310; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_613324 = newJObject()
  add(query_613324, "nextToken", newJString(nextToken))
  add(query_613324, "maxResults", newJInt(maxResults))
  result = call_613323.call(nil, query_613324, nil, nil, nil)

var listDatasets* = Call_ListDatasets_613310(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_613311, base: "/",
    url: url_ListDatasets_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_613355 = ref object of OpenApiRestCall_612658
proc url_CreateDatasetContent_613357(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDatasetContent_613356(path: JsonNode; query: JsonNode;
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
  var valid_613358 = path.getOrDefault("datasetName")
  valid_613358 = validateParameter(valid_613358, JString, required = true,
                                 default = nil)
  if valid_613358 != nil:
    section.add "datasetName", valid_613358
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613366: Call_CreateDatasetContent_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_613366.validator(path, query, header, formData, body)
  let scheme = call_613366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613366.url(scheme.get, call_613366.host, call_613366.base,
                         call_613366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613366, url, valid)

proc call*(call_613367: Call_CreateDatasetContent_613355; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_613368 = newJObject()
  add(path_613368, "datasetName", newJString(datasetName))
  result = call_613367.call(path_613368, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_613355(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_613356, base: "/",
    url: url_CreateDatasetContent_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_613339 = ref object of OpenApiRestCall_612658
proc url_GetDatasetContent_613341(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDatasetContent_613340(path: JsonNode; query: JsonNode;
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
  var valid_613342 = path.getOrDefault("datasetName")
  valid_613342 = validateParameter(valid_613342, JString, required = true,
                                 default = nil)
  if valid_613342 != nil:
    section.add "datasetName", valid_613342
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_613343 = query.getOrDefault("versionId")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "versionId", valid_613343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_GetDatasetContent_613339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_GetDatasetContent_613339; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_613353 = newJObject()
  var query_613354 = newJObject()
  add(query_613354, "versionId", newJString(versionId))
  add(path_613353, "datasetName", newJString(datasetName))
  result = call_613352.call(path_613353, query_613354, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_613339(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_613340, base: "/",
    url: url_GetDatasetContent_613341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_613369 = ref object of OpenApiRestCall_612658
proc url_DeleteDatasetContent_613371(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDatasetContent_613370(path: JsonNode; query: JsonNode;
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
  var valid_613372 = path.getOrDefault("datasetName")
  valid_613372 = validateParameter(valid_613372, JString, required = true,
                                 default = nil)
  if valid_613372 != nil:
    section.add "datasetName", valid_613372
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_613373 = query.getOrDefault("versionId")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "versionId", valid_613373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_DeleteDatasetContent_613369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_DeleteDatasetContent_613369; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_613383 = newJObject()
  var query_613384 = newJObject()
  add(query_613384, "versionId", newJString(versionId))
  add(path_613383, "datasetName", newJString(datasetName))
  result = call_613382.call(path_613383, query_613384, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_613369(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_613370, base: "/",
    url: url_DeleteDatasetContent_613371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_613400 = ref object of OpenApiRestCall_612658
proc url_CreateDatastore_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatastore_613401(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_CreateDatastore_613400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_CreateDatastore_613400; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_613413 = newJObject()
  if body != nil:
    body_613413 = body
  result = call_613412.call(nil, nil, nil, nil, body_613413)

var createDatastore* = Call_CreateDatastore_613400(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_613401, base: "/",
    url: url_CreateDatastore_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_613385 = ref object of OpenApiRestCall_612658
proc url_ListDatastores_613387(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatastores_613386(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of data stores.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  section = newJObject()
  var valid_613388 = query.getOrDefault("nextToken")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "nextToken", valid_613388
  var valid_613389 = query.getOrDefault("maxResults")
  valid_613389 = validateParameter(valid_613389, JInt, required = false, default = nil)
  if valid_613389 != nil:
    section.add "maxResults", valid_613389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_ListDatastores_613385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_ListDatastores_613385; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_613399 = newJObject()
  add(query_613399, "nextToken", newJString(nextToken))
  add(query_613399, "maxResults", newJInt(maxResults))
  result = call_613398.call(nil, query_613399, nil, nil, nil)

var listDatastores* = Call_ListDatastores_613385(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_613386, base: "/",
    url: url_ListDatastores_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_613429 = ref object of OpenApiRestCall_612658
proc url_CreatePipeline_613431(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_613430(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613432 = header.getOrDefault("X-Amz-Signature")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Signature", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Content-Sha256", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Date")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Date", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Credential")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Credential", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Security-Token")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Security-Token", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Algorithm")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Algorithm", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-SignedHeaders", valid_613438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613440: Call_CreatePipeline_613429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_613440.validator(path, query, header, formData, body)
  let scheme = call_613440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613440.url(scheme.get, call_613440.host, call_613440.base,
                         call_613440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613440, url, valid)

proc call*(call_613441: Call_CreatePipeline_613429; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_613442 = newJObject()
  if body != nil:
    body_613442 = body
  result = call_613441.call(nil, nil, nil, nil, body_613442)

var createPipeline* = Call_CreatePipeline_613429(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_613430, base: "/",
    url: url_CreatePipeline_613431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_613414 = ref object of OpenApiRestCall_612658
proc url_ListPipelines_613416(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_613415(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of pipelines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  section = newJObject()
  var valid_613417 = query.getOrDefault("nextToken")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "nextToken", valid_613417
  var valid_613418 = query.getOrDefault("maxResults")
  valid_613418 = validateParameter(valid_613418, JInt, required = false, default = nil)
  if valid_613418 != nil:
    section.add "maxResults", valid_613418
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_ListPipelines_613414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_ListPipelines_613414; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_613428 = newJObject()
  add(query_613428, "nextToken", newJString(nextToken))
  add(query_613428, "maxResults", newJInt(maxResults))
  result = call_613427.call(nil, query_613428, nil, nil, nil)

var listPipelines* = Call_ListPipelines_613414(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_613415, base: "/",
    url: url_ListPipelines_613416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_613459 = ref object of OpenApiRestCall_612658
proc url_UpdateChannel_613461(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_613460(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613462 = path.getOrDefault("channelName")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "channelName", valid_613462
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_UpdateChannel_613459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_UpdateChannel_613459; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_613473 = newJObject()
  var body_613474 = newJObject()
  add(path_613473, "channelName", newJString(channelName))
  if body != nil:
    body_613474 = body
  result = call_613472.call(path_613473, nil, nil, nil, body_613474)

var updateChannel* = Call_UpdateChannel_613459(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_613460,
    base: "/", url: url_UpdateChannel_613461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_613443 = ref object of OpenApiRestCall_612658
proc url_DescribeChannel_613445(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_613444(path: JsonNode; query: JsonNode;
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
  var valid_613446 = path.getOrDefault("channelName")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "channelName", valid_613446
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_613447 = query.getOrDefault("includeStatistics")
  valid_613447 = validateParameter(valid_613447, JBool, required = false, default = nil)
  if valid_613447 != nil:
    section.add "includeStatistics", valid_613447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613448 = header.getOrDefault("X-Amz-Signature")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Signature", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Content-Sha256", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Date")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Date", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Credential")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Credential", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Security-Token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Security-Token", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Algorithm")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Algorithm", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-SignedHeaders", valid_613454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613455: Call_DescribeChannel_613443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_613455.validator(path, query, header, formData, body)
  let scheme = call_613455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613455.url(scheme.get, call_613455.host, call_613455.base,
                         call_613455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613455, url, valid)

proc call*(call_613456: Call_DescribeChannel_613443; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  var path_613457 = newJObject()
  var query_613458 = newJObject()
  add(path_613457, "channelName", newJString(channelName))
  add(query_613458, "includeStatistics", newJBool(includeStatistics))
  result = call_613456.call(path_613457, query_613458, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_613443(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_613444,
    base: "/", url: url_DescribeChannel_613445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_613475 = ref object of OpenApiRestCall_612658
proc url_DeleteChannel_613477(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_613476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613478 = path.getOrDefault("channelName")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "channelName", valid_613478
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613486: Call_DeleteChannel_613475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_613486.validator(path, query, header, formData, body)
  let scheme = call_613486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613486.url(scheme.get, call_613486.host, call_613486.base,
                         call_613486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613486, url, valid)

proc call*(call_613487: Call_DeleteChannel_613475; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_613488 = newJObject()
  add(path_613488, "channelName", newJString(channelName))
  result = call_613487.call(path_613488, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_613475(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_613476,
    base: "/", url: url_DeleteChannel_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_613503 = ref object of OpenApiRestCall_612658
proc url_UpdateDataset_613505(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataset_613504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613506 = path.getOrDefault("datasetName")
  valid_613506 = validateParameter(valid_613506, JString, required = true,
                                 default = nil)
  if valid_613506 != nil:
    section.add "datasetName", valid_613506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613507 = header.getOrDefault("X-Amz-Signature")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Signature", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Content-Sha256", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Date")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Date", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Credential")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Credential", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Security-Token")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Security-Token", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Algorithm")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Algorithm", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-SignedHeaders", valid_613513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_UpdateDataset_613503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_UpdateDataset_613503; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_613517 = newJObject()
  var body_613518 = newJObject()
  add(path_613517, "datasetName", newJString(datasetName))
  if body != nil:
    body_613518 = body
  result = call_613516.call(path_613517, nil, nil, nil, body_613518)

var updateDataset* = Call_UpdateDataset_613503(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_613504,
    base: "/", url: url_UpdateDataset_613505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_613489 = ref object of OpenApiRestCall_612658
proc url_DescribeDataset_613491(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataset_613490(path: JsonNode; query: JsonNode;
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
  var valid_613492 = path.getOrDefault("datasetName")
  valid_613492 = validateParameter(valid_613492, JString, required = true,
                                 default = nil)
  if valid_613492 != nil:
    section.add "datasetName", valid_613492
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613493 = header.getOrDefault("X-Amz-Signature")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Signature", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Content-Sha256", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Date")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Date", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Credential")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Credential", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Security-Token")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Security-Token", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Algorithm")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Algorithm", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-SignedHeaders", valid_613499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613500: Call_DescribeDataset_613489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_613500.validator(path, query, header, formData, body)
  let scheme = call_613500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613500.url(scheme.get, call_613500.host, call_613500.base,
                         call_613500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613500, url, valid)

proc call*(call_613501: Call_DescribeDataset_613489; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_613502 = newJObject()
  add(path_613502, "datasetName", newJString(datasetName))
  result = call_613501.call(path_613502, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_613489(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_613490,
    base: "/", url: url_DescribeDataset_613491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_613519 = ref object of OpenApiRestCall_612658
proc url_DeleteDataset_613521(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataset_613520(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613522 = path.getOrDefault("datasetName")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = nil)
  if valid_613522 != nil:
    section.add "datasetName", valid_613522
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613523 = header.getOrDefault("X-Amz-Signature")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Signature", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Content-Sha256", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Date")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Date", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Credential")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Credential", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Security-Token")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Security-Token", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Algorithm")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Algorithm", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-SignedHeaders", valid_613529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613530: Call_DeleteDataset_613519; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_613530.validator(path, query, header, formData, body)
  let scheme = call_613530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613530.url(scheme.get, call_613530.host, call_613530.base,
                         call_613530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613530, url, valid)

proc call*(call_613531: Call_DeleteDataset_613519; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_613532 = newJObject()
  add(path_613532, "datasetName", newJString(datasetName))
  result = call_613531.call(path_613532, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_613519(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_613520,
    base: "/", url: url_DeleteDataset_613521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_613549 = ref object of OpenApiRestCall_612658
proc url_UpdateDatastore_613551(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDatastore_613550(path: JsonNode; query: JsonNode;
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
  var valid_613552 = path.getOrDefault("datastoreName")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "datastoreName", valid_613552
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613553 = header.getOrDefault("X-Amz-Signature")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Signature", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Content-Sha256", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Date")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Date", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Credential")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Credential", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Security-Token")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Security-Token", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Algorithm")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Algorithm", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-SignedHeaders", valid_613559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613561: Call_UpdateDatastore_613549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_613561.validator(path, query, header, formData, body)
  let scheme = call_613561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613561.url(scheme.get, call_613561.host, call_613561.base,
                         call_613561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613561, url, valid)

proc call*(call_613562: Call_UpdateDatastore_613549; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_613563 = newJObject()
  var body_613564 = newJObject()
  add(path_613563, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_613564 = body
  result = call_613562.call(path_613563, nil, nil, nil, body_613564)

var updateDatastore* = Call_UpdateDatastore_613549(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_613550,
    base: "/", url: url_UpdateDatastore_613551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_613533 = ref object of OpenApiRestCall_612658
proc url_DescribeDatastore_613535(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDatastore_613534(path: JsonNode; query: JsonNode;
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
  var valid_613536 = path.getOrDefault("datastoreName")
  valid_613536 = validateParameter(valid_613536, JString, required = true,
                                 default = nil)
  if valid_613536 != nil:
    section.add "datastoreName", valid_613536
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_613537 = query.getOrDefault("includeStatistics")
  valid_613537 = validateParameter(valid_613537, JBool, required = false, default = nil)
  if valid_613537 != nil:
    section.add "includeStatistics", valid_613537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613538 = header.getOrDefault("X-Amz-Signature")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Signature", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Content-Sha256", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Date")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Date", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Credential")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Credential", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Security-Token")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Security-Token", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Algorithm")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Algorithm", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-SignedHeaders", valid_613544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_DescribeDatastore_613533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_DescribeDatastore_613533; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  var path_613547 = newJObject()
  var query_613548 = newJObject()
  add(path_613547, "datastoreName", newJString(datastoreName))
  add(query_613548, "includeStatistics", newJBool(includeStatistics))
  result = call_613546.call(path_613547, query_613548, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_613533(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_613534,
    base: "/", url: url_DescribeDatastore_613535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_613565 = ref object of OpenApiRestCall_612658
proc url_DeleteDatastore_613567(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDatastore_613566(path: JsonNode; query: JsonNode;
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
  var valid_613568 = path.getOrDefault("datastoreName")
  valid_613568 = validateParameter(valid_613568, JString, required = true,
                                 default = nil)
  if valid_613568 != nil:
    section.add "datastoreName", valid_613568
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613576: Call_DeleteDatastore_613565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_613576.validator(path, query, header, formData, body)
  let scheme = call_613576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613576.url(scheme.get, call_613576.host, call_613576.base,
                         call_613576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613576, url, valid)

proc call*(call_613577: Call_DeleteDatastore_613565; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_613578 = newJObject()
  add(path_613578, "datastoreName", newJString(datastoreName))
  result = call_613577.call(path_613578, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_613565(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_613566,
    base: "/", url: url_DeleteDatastore_613567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_613593 = ref object of OpenApiRestCall_612658
proc url_UpdatePipeline_613595(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipeline_613594(path: JsonNode; query: JsonNode;
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
  var valid_613596 = path.getOrDefault("pipelineName")
  valid_613596 = validateParameter(valid_613596, JString, required = true,
                                 default = nil)
  if valid_613596 != nil:
    section.add "pipelineName", valid_613596
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613597 = header.getOrDefault("X-Amz-Signature")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Signature", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Content-Sha256", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Date")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Date", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Credential")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Credential", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Security-Token")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Security-Token", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Algorithm")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Algorithm", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-SignedHeaders", valid_613603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613605: Call_UpdatePipeline_613593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_613605.validator(path, query, header, formData, body)
  let scheme = call_613605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613605.url(scheme.get, call_613605.host, call_613605.base,
                         call_613605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613605, url, valid)

proc call*(call_613606: Call_UpdatePipeline_613593; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_613607 = newJObject()
  var body_613608 = newJObject()
  add(path_613607, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_613608 = body
  result = call_613606.call(path_613607, nil, nil, nil, body_613608)

var updatePipeline* = Call_UpdatePipeline_613593(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_613594,
    base: "/", url: url_UpdatePipeline_613595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_613579 = ref object of OpenApiRestCall_612658
proc url_DescribePipeline_613581(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePipeline_613580(path: JsonNode; query: JsonNode;
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
  var valid_613582 = path.getOrDefault("pipelineName")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = nil)
  if valid_613582 != nil:
    section.add "pipelineName", valid_613582
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613590: Call_DescribePipeline_613579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_613590.validator(path, query, header, formData, body)
  let scheme = call_613590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613590.url(scheme.get, call_613590.host, call_613590.base,
                         call_613590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613590, url, valid)

proc call*(call_613591: Call_DescribePipeline_613579; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_613592 = newJObject()
  add(path_613592, "pipelineName", newJString(pipelineName))
  result = call_613591.call(path_613592, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_613579(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_613580,
    base: "/", url: url_DescribePipeline_613581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_613609 = ref object of OpenApiRestCall_612658
proc url_DeletePipeline_613611(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePipeline_613610(path: JsonNode; query: JsonNode;
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
  var valid_613612 = path.getOrDefault("pipelineName")
  valid_613612 = validateParameter(valid_613612, JString, required = true,
                                 default = nil)
  if valid_613612 != nil:
    section.add "pipelineName", valid_613612
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613613 = header.getOrDefault("X-Amz-Signature")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Signature", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Content-Sha256", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Date")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Date", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Credential")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Credential", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Security-Token")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Security-Token", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Algorithm")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Algorithm", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-SignedHeaders", valid_613619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613620: Call_DeletePipeline_613609; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_613620.validator(path, query, header, formData, body)
  let scheme = call_613620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613620.url(scheme.get, call_613620.host, call_613620.base,
                         call_613620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613620, url, valid)

proc call*(call_613621: Call_DeletePipeline_613609; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_613622 = newJObject()
  add(path_613622, "pipelineName", newJString(pipelineName))
  result = call_613621.call(path_613622, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_613609(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_613610,
    base: "/", url: url_DeletePipeline_613611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_613635 = ref object of OpenApiRestCall_612658
proc url_PutLoggingOptions_613637(protocol: Scheme; host: string; base: string;
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

proc validate_PutLoggingOptions_613636(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613638 = header.getOrDefault("X-Amz-Signature")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Signature", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Content-Sha256", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Date")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Date", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Credential")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Credential", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Security-Token")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Security-Token", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Algorithm")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Algorithm", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-SignedHeaders", valid_613644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613646: Call_PutLoggingOptions_613635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_613646.validator(path, query, header, formData, body)
  let scheme = call_613646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613646.url(scheme.get, call_613646.host, call_613646.base,
                         call_613646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613646, url, valid)

proc call*(call_613647: Call_PutLoggingOptions_613635; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_613648 = newJObject()
  if body != nil:
    body_613648 = body
  result = call_613647.call(nil, nil, nil, nil, body_613648)

var putLoggingOptions* = Call_PutLoggingOptions_613635(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_613636, base: "/",
    url: url_PutLoggingOptions_613637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_613623 = ref object of OpenApiRestCall_612658
proc url_DescribeLoggingOptions_613625(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLoggingOptions_613624(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613626 = header.getOrDefault("X-Amz-Signature")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Signature", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Content-Sha256", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Date")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Date", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Credential")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Credential", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Security-Token")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Security-Token", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Algorithm")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Algorithm", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-SignedHeaders", valid_613632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613633: Call_DescribeLoggingOptions_613623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_613633.validator(path, query, header, formData, body)
  let scheme = call_613633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613633.url(scheme.get, call_613633.host, call_613633.base,
                         call_613633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613633, url, valid)

proc call*(call_613634: Call_DescribeLoggingOptions_613623): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_613634.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_613623(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_613624, base: "/",
    url: url_DescribeLoggingOptions_613625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_613649 = ref object of OpenApiRestCall_612658
proc url_ListDatasetContents_613651(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDatasetContents_613650(path: JsonNode; query: JsonNode;
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
  var valid_613652 = path.getOrDefault("datasetName")
  valid_613652 = validateParameter(valid_613652, JString, required = true,
                                 default = nil)
  if valid_613652 != nil:
    section.add "datasetName", valid_613652
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   scheduledOnOrAfter: JString
  ##                     : A filter to limit results to those data set contents whose creation is scheduled on or after the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   scheduledBefore: JString
  ##                  : A filter to limit results to those data set contents whose creation is scheduled before the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   maxResults: JInt
  ##             : The maximum number of results to return in this request.
  section = newJObject()
  var valid_613653 = query.getOrDefault("nextToken")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "nextToken", valid_613653
  var valid_613654 = query.getOrDefault("scheduledOnOrAfter")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "scheduledOnOrAfter", valid_613654
  var valid_613655 = query.getOrDefault("scheduledBefore")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "scheduledBefore", valid_613655
  var valid_613656 = query.getOrDefault("maxResults")
  valid_613656 = validateParameter(valid_613656, JInt, required = false, default = nil)
  if valid_613656 != nil:
    section.add "maxResults", valid_613656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613657 = header.getOrDefault("X-Amz-Signature")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Signature", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Content-Sha256", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Date")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Date", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Credential")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Credential", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Security-Token")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Security-Token", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Algorithm")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Algorithm", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-SignedHeaders", valid_613663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613664: Call_ListDatasetContents_613649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_613664.validator(path, query, header, formData, body)
  let scheme = call_613664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613664.url(scheme.get, call_613664.host, call_613664.base,
                         call_613664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613664, url, valid)

proc call*(call_613665: Call_ListDatasetContents_613649; datasetName: string;
          nextToken: string = ""; scheduledOnOrAfter: string = "";
          scheduledBefore: string = ""; maxResults: int = 0): Recallable =
  ## listDatasetContents
  ## Lists information about data set contents that have been created.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   scheduledOnOrAfter: string
  ##                     : A filter to limit results to those data set contents whose creation is scheduled on or after the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents information you want to list.
  ##   scheduledBefore: string
  ##                  : A filter to limit results to those data set contents whose creation is scheduled before the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   maxResults: int
  ##             : The maximum number of results to return in this request.
  var path_613666 = newJObject()
  var query_613667 = newJObject()
  add(query_613667, "nextToken", newJString(nextToken))
  add(query_613667, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(path_613666, "datasetName", newJString(datasetName))
  add(query_613667, "scheduledBefore", newJString(scheduledBefore))
  add(query_613667, "maxResults", newJInt(maxResults))
  result = call_613665.call(path_613666, query_613667, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_613649(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_613650, base: "/",
    url: url_ListDatasetContents_613651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613682 = ref object of OpenApiRestCall_612658
proc url_TagResource_613684(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613683(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613685 = query.getOrDefault("resourceArn")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = nil)
  if valid_613685 != nil:
    section.add "resourceArn", valid_613685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613686 = header.getOrDefault("X-Amz-Signature")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Signature", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Content-Sha256", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Date")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Date", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Credential")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Credential", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Security-Token")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Security-Token", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Algorithm")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Algorithm", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-SignedHeaders", valid_613692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_TagResource_613682; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_TagResource_613682; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  var query_613696 = newJObject()
  var body_613697 = newJObject()
  if body != nil:
    body_613697 = body
  add(query_613696, "resourceArn", newJString(resourceArn))
  result = call_613695.call(nil, query_613696, nil, nil, body_613697)

var tagResource* = Call_TagResource_613682(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_613683,
                                        base: "/", url: url_TagResource_613684,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613668 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613670(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613669(path: JsonNode; query: JsonNode;
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
  var valid_613671 = query.getOrDefault("resourceArn")
  valid_613671 = validateParameter(valid_613671, JString, required = true,
                                 default = nil)
  if valid_613671 != nil:
    section.add "resourceArn", valid_613671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613672 = header.getOrDefault("X-Amz-Signature")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Signature", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Content-Sha256", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Date")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Date", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Credential")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Credential", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Security-Token")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Security-Token", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Algorithm")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Algorithm", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-SignedHeaders", valid_613678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613679: Call_ListTagsForResource_613668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_613679.validator(path, query, header, formData, body)
  let scheme = call_613679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613679.url(scheme.get, call_613679.host, call_613679.base,
                         call_613679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613679, url, valid)

proc call*(call_613680: Call_ListTagsForResource_613668; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_613681 = newJObject()
  add(query_613681, "resourceArn", newJString(resourceArn))
  result = call_613680.call(nil, query_613681, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613668(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_613669, base: "/",
    url: url_ListTagsForResource_613670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_613698 = ref object of OpenApiRestCall_612658
proc url_RunPipelineActivity_613700(protocol: Scheme; host: string; base: string;
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

proc validate_RunPipelineActivity_613699(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613701 = header.getOrDefault("X-Amz-Signature")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Signature", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Content-Sha256", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Date")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Date", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Credential")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Credential", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Security-Token")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Security-Token", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Algorithm")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Algorithm", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-SignedHeaders", valid_613707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613709: Call_RunPipelineActivity_613698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_613709.validator(path, query, header, formData, body)
  let scheme = call_613709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613709.url(scheme.get, call_613709.host, call_613709.base,
                         call_613709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613709, url, valid)

proc call*(call_613710: Call_RunPipelineActivity_613698; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_613711 = newJObject()
  if body != nil:
    body_613711 = body
  result = call_613710.call(nil, nil, nil, nil, body_613711)

var runPipelineActivity* = Call_RunPipelineActivity_613698(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_613699, base: "/",
    url: url_RunPipelineActivity_613700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_613712 = ref object of OpenApiRestCall_612658
proc url_SampleChannelData_613714(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SampleChannelData_613713(path: JsonNode; query: JsonNode;
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
  var valid_613715 = path.getOrDefault("channelName")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "channelName", valid_613715
  result.add "path", section
  ## parameters in `query` object:
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_613716 = query.getOrDefault("startTime")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "startTime", valid_613716
  var valid_613717 = query.getOrDefault("maxMessages")
  valid_613717 = validateParameter(valid_613717, JInt, required = false, default = nil)
  if valid_613717 != nil:
    section.add "maxMessages", valid_613717
  var valid_613718 = query.getOrDefault("endTime")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "endTime", valid_613718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613726: Call_SampleChannelData_613712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_613726.validator(path, query, header, formData, body)
  let scheme = call_613726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613726.url(scheme.get, call_613726.host, call_613726.base,
                         call_613726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613726, url, valid)

proc call*(call_613727: Call_SampleChannelData_613712; channelName: string;
          startTime: string = ""; maxMessages: int = 0; endTime: string = ""): Recallable =
  ## sampleChannelData
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ##   startTime: string
  ##            : The start of the time window from which sample messages are retrieved.
  ##   maxMessages: int
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   channelName: string (required)
  ##              : The name of the channel whose message samples are retrieved.
  ##   endTime: string
  ##          : The end of the time window from which sample messages are retrieved.
  var path_613728 = newJObject()
  var query_613729 = newJObject()
  add(query_613729, "startTime", newJString(startTime))
  add(query_613729, "maxMessages", newJInt(maxMessages))
  add(path_613728, "channelName", newJString(channelName))
  add(query_613729, "endTime", newJString(endTime))
  result = call_613727.call(path_613728, query_613729, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_613712(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_613713, base: "/",
    url: url_SampleChannelData_613714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_613730 = ref object of OpenApiRestCall_612658
proc url_StartPipelineReprocessing_613732(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartPipelineReprocessing_613731(path: JsonNode; query: JsonNode;
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
  var valid_613733 = path.getOrDefault("pipelineName")
  valid_613733 = validateParameter(valid_613733, JString, required = true,
                                 default = nil)
  if valid_613733 != nil:
    section.add "pipelineName", valid_613733
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613742: Call_StartPipelineReprocessing_613730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_613742.validator(path, query, header, formData, body)
  let scheme = call_613742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613742.url(scheme.get, call_613742.host, call_613742.base,
                         call_613742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613742, url, valid)

proc call*(call_613743: Call_StartPipelineReprocessing_613730;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_613744 = newJObject()
  var body_613745 = newJObject()
  add(path_613744, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_613745 = body
  result = call_613743.call(path_613744, nil, nil, nil, body_613745)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_613730(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_613731, base: "/",
    url: url_StartPipelineReprocessing_613732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613746 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613748(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613747(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the given tags (metadata) from the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource whose tags you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613749 = query.getOrDefault("tagKeys")
  valid_613749 = validateParameter(valid_613749, JArray, required = true, default = nil)
  if valid_613749 != nil:
    section.add "tagKeys", valid_613749
  var valid_613750 = query.getOrDefault("resourceArn")
  valid_613750 = validateParameter(valid_613750, JString, required = true,
                                 default = nil)
  if valid_613750 != nil:
    section.add "resourceArn", valid_613750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613758: Call_UntagResource_613746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_613758.validator(path, query, header, formData, body)
  let scheme = call_613758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613758.url(scheme.get, call_613758.host, call_613758.base,
                         call_613758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613758, url, valid)

proc call*(call_613759: Call_UntagResource_613746; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  var query_613760 = newJObject()
  if tagKeys != nil:
    query_613760.add "tagKeys", tagKeys
  add(query_613760, "resourceArn", newJString(resourceArn))
  result = call_613759.call(nil, query_613760, nil, nil, nil)

var untagResource* = Call_UntagResource_613746(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_613747,
    base: "/", url: url_UntagResource_613748, schemes: {Scheme.Https, Scheme.Http})
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
