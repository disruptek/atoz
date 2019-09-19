
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_772933 = ref object of OpenApiRestCall_772597
proc url_BatchPutMessage_772935(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchPutMessage_772934(path: JsonNode; query: JsonNode;
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
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_BatchPutMessage_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_BatchPutMessage_772933; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var batchPutMessage* = Call_BatchPutMessage_772933(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_772934, base: "/",
    url: url_BatchPutMessage_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_773188 = ref object of OpenApiRestCall_772597
proc url_CancelPipelineReprocessing_773190(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CancelPipelineReprocessing_773189(path: JsonNode; query: JsonNode;
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
  var valid_773205 = path.getOrDefault("reprocessingId")
  valid_773205 = validateParameter(valid_773205, JString, required = true,
                                 default = nil)
  if valid_773205 != nil:
    section.add "reprocessingId", valid_773205
  var valid_773206 = path.getOrDefault("pipelineName")
  valid_773206 = validateParameter(valid_773206, JString, required = true,
                                 default = nil)
  if valid_773206 != nil:
    section.add "pipelineName", valid_773206
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
  var valid_773207 = header.getOrDefault("X-Amz-Date")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Date", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Security-Token")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Security-Token", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Content-Sha256", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Algorithm")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Algorithm", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Signature")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Signature", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-SignedHeaders", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Credential")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Credential", valid_773213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_CancelPipelineReprocessing_773188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_CancelPipelineReprocessing_773188;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_773216 = newJObject()
  add(path_773216, "reprocessingId", newJString(reprocessingId))
  add(path_773216, "pipelineName", newJString(pipelineName))
  result = call_773215.call(path_773216, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_773188(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_773189, base: "/",
    url: url_CancelPipelineReprocessing_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_773233 = ref object of OpenApiRestCall_772597
proc url_CreateChannel_773235(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateChannel_773234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773236 = header.getOrDefault("X-Amz-Date")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Date", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Security-Token")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Security-Token", valid_773237
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

proc call*(call_773244: Call_CreateChannel_773233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_CreateChannel_773233; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var createChannel* = Call_CreateChannel_773233(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_773234, base: "/",
    url: url_CreateChannel_773235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_773218 = ref object of OpenApiRestCall_772597
proc url_ListChannels_773220(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListChannels_773219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773221 = query.getOrDefault("maxResults")
  valid_773221 = validateParameter(valid_773221, JInt, required = false, default = nil)
  if valid_773221 != nil:
    section.add "maxResults", valid_773221
  var valid_773222 = query.getOrDefault("nextToken")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "nextToken", valid_773222
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
  var valid_773223 = header.getOrDefault("X-Amz-Date")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Date", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Security-Token")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Security-Token", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Content-Sha256", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Algorithm")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Algorithm", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Signature")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Signature", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-SignedHeaders", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Credential")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Credential", valid_773229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773230: Call_ListChannels_773218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_773230.validator(path, query, header, formData, body)
  let scheme = call_773230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773230.url(scheme.get, call_773230.host, call_773230.base,
                         call_773230.route, valid.getOrDefault("path"))
  result = hook(call_773230, url, valid)

proc call*(call_773231: Call_ListChannels_773218; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_773232 = newJObject()
  add(query_773232, "maxResults", newJInt(maxResults))
  add(query_773232, "nextToken", newJString(nextToken))
  result = call_773231.call(nil, query_773232, nil, nil, nil)

var listChannels* = Call_ListChannels_773218(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_773219, base: "/",
    url: url_ListChannels_773220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_773262 = ref object of OpenApiRestCall_772597
proc url_CreateDataset_773264(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDataset_773263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Content-Sha256", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Algorithm", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Signature", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-SignedHeaders", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Credential")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Credential", valid_773271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773273: Call_CreateDataset_773262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_773273.validator(path, query, header, formData, body)
  let scheme = call_773273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773273.url(scheme.get, call_773273.host, call_773273.base,
                         call_773273.route, valid.getOrDefault("path"))
  result = hook(call_773273, url, valid)

proc call*(call_773274: Call_CreateDataset_773262; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_773275 = newJObject()
  if body != nil:
    body_773275 = body
  result = call_773274.call(nil, nil, nil, nil, body_773275)

var createDataset* = Call_CreateDataset_773262(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_773263, base: "/",
    url: url_CreateDataset_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_773247 = ref object of OpenApiRestCall_772597
proc url_ListDatasets_773249(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDatasets_773248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773250 = query.getOrDefault("maxResults")
  valid_773250 = validateParameter(valid_773250, JInt, required = false, default = nil)
  if valid_773250 != nil:
    section.add "maxResults", valid_773250
  var valid_773251 = query.getOrDefault("nextToken")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "nextToken", valid_773251
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
  var valid_773252 = header.getOrDefault("X-Amz-Date")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Date", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Security-Token")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Security-Token", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Content-Sha256", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Algorithm")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Algorithm", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Signature")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Signature", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-SignedHeaders", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Credential")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Credential", valid_773258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_ListDatasets_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_ListDatasets_773247; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_773261 = newJObject()
  add(query_773261, "maxResults", newJInt(maxResults))
  add(query_773261, "nextToken", newJString(nextToken))
  result = call_773260.call(nil, query_773261, nil, nil, nil)

var listDatasets* = Call_ListDatasets_773247(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_773248, base: "/",
    url: url_ListDatasets_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_773292 = ref object of OpenApiRestCall_772597
proc url_CreateDatasetContent_773294(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDatasetContent_773293(path: JsonNode; query: JsonNode;
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
  var valid_773295 = path.getOrDefault("datasetName")
  valid_773295 = validateParameter(valid_773295, JString, required = true,
                                 default = nil)
  if valid_773295 != nil:
    section.add "datasetName", valid_773295
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
  var valid_773296 = header.getOrDefault("X-Amz-Date")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Date", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Security-Token")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Security-Token", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773303: Call_CreateDatasetContent_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_773303.validator(path, query, header, formData, body)
  let scheme = call_773303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773303.url(scheme.get, call_773303.host, call_773303.base,
                         call_773303.route, valid.getOrDefault("path"))
  result = hook(call_773303, url, valid)

proc call*(call_773304: Call_CreateDatasetContent_773292; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_773305 = newJObject()
  add(path_773305, "datasetName", newJString(datasetName))
  result = call_773304.call(path_773305, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_773292(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_773293, base: "/",
    url: url_CreateDatasetContent_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_773276 = ref object of OpenApiRestCall_772597
proc url_GetDatasetContent_773278(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDatasetContent_773277(path: JsonNode; query: JsonNode;
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
  var valid_773279 = path.getOrDefault("datasetName")
  valid_773279 = validateParameter(valid_773279, JString, required = true,
                                 default = nil)
  if valid_773279 != nil:
    section.add "datasetName", valid_773279
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_773280 = query.getOrDefault("versionId")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "versionId", valid_773280
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
  var valid_773281 = header.getOrDefault("X-Amz-Date")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Date", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Security-Token")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Security-Token", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773288: Call_GetDatasetContent_773276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_773288.validator(path, query, header, formData, body)
  let scheme = call_773288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773288.url(scheme.get, call_773288.host, call_773288.base,
                         call_773288.route, valid.getOrDefault("path"))
  result = hook(call_773288, url, valid)

proc call*(call_773289: Call_GetDatasetContent_773276; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_773290 = newJObject()
  var query_773291 = newJObject()
  add(query_773291, "versionId", newJString(versionId))
  add(path_773290, "datasetName", newJString(datasetName))
  result = call_773289.call(path_773290, query_773291, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_773276(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_773277, base: "/",
    url: url_GetDatasetContent_773278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_773306 = ref object of OpenApiRestCall_772597
proc url_DeleteDatasetContent_773308(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/content")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDatasetContent_773307(path: JsonNode; query: JsonNode;
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
  var valid_773309 = path.getOrDefault("datasetName")
  valid_773309 = validateParameter(valid_773309, JString, required = true,
                                 default = nil)
  if valid_773309 != nil:
    section.add "datasetName", valid_773309
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_773310 = query.getOrDefault("versionId")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "versionId", valid_773310
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
  var valid_773311 = header.getOrDefault("X-Amz-Date")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Date", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Security-Token")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Security-Token", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773318: Call_DeleteDatasetContent_773306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_773318.validator(path, query, header, formData, body)
  let scheme = call_773318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773318.url(scheme.get, call_773318.host, call_773318.base,
                         call_773318.route, valid.getOrDefault("path"))
  result = hook(call_773318, url, valid)

proc call*(call_773319: Call_DeleteDatasetContent_773306; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_773320 = newJObject()
  var query_773321 = newJObject()
  add(query_773321, "versionId", newJString(versionId))
  add(path_773320, "datasetName", newJString(datasetName))
  result = call_773319.call(path_773320, query_773321, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_773306(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_773307, base: "/",
    url: url_DeleteDatasetContent_773308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_773337 = ref object of OpenApiRestCall_772597
proc url_CreateDatastore_773339(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDatastore_773338(path: JsonNode; query: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Content-Sha256", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Algorithm")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Algorithm", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Signature")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Signature", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-SignedHeaders", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Credential")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Credential", valid_773346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_CreateDatastore_773337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_CreateDatastore_773337; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_773350 = newJObject()
  if body != nil:
    body_773350 = body
  result = call_773349.call(nil, nil, nil, nil, body_773350)

var createDatastore* = Call_CreateDatastore_773337(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_773338, base: "/",
    url: url_CreateDatastore_773339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_773322 = ref object of OpenApiRestCall_772597
proc url_ListDatastores_773324(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDatastores_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = query.getOrDefault("maxResults")
  valid_773325 = validateParameter(valid_773325, JInt, required = false, default = nil)
  if valid_773325 != nil:
    section.add "maxResults", valid_773325
  var valid_773326 = query.getOrDefault("nextToken")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "nextToken", valid_773326
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
  var valid_773327 = header.getOrDefault("X-Amz-Date")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Date", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Security-Token")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Security-Token", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Content-Sha256", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Algorithm")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Algorithm", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Signature")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Signature", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-SignedHeaders", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Credential")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Credential", valid_773333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_ListDatastores_773322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_ListDatastores_773322; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_773336 = newJObject()
  add(query_773336, "maxResults", newJInt(maxResults))
  add(query_773336, "nextToken", newJString(nextToken))
  result = call_773335.call(nil, query_773336, nil, nil, nil)

var listDatastores* = Call_ListDatastores_773322(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_773323, base: "/",
    url: url_ListDatastores_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_773366 = ref object of OpenApiRestCall_772597
proc url_CreatePipeline_773368(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePipeline_773367(path: JsonNode; query: JsonNode;
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
  var valid_773369 = header.getOrDefault("X-Amz-Date")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Date", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Security-Token")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Security-Token", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Content-Sha256", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Algorithm")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Algorithm", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Signature")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Signature", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-SignedHeaders", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Credential")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Credential", valid_773375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773377: Call_CreatePipeline_773366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from one or more channels and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_773377.validator(path, query, header, formData, body)
  let scheme = call_773377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773377.url(scheme.get, call_773377.host, call_773377.base,
                         call_773377.route, valid.getOrDefault("path"))
  result = hook(call_773377, url, valid)

proc call*(call_773378: Call_CreatePipeline_773366; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from one or more channels and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_773379 = newJObject()
  if body != nil:
    body_773379 = body
  result = call_773378.call(nil, nil, nil, nil, body_773379)

var createPipeline* = Call_CreatePipeline_773366(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_773367, base: "/",
    url: url_CreatePipeline_773368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_773351 = ref object of OpenApiRestCall_772597
proc url_ListPipelines_773353(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPipelines_773352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773354 = query.getOrDefault("maxResults")
  valid_773354 = validateParameter(valid_773354, JInt, required = false, default = nil)
  if valid_773354 != nil:
    section.add "maxResults", valid_773354
  var valid_773355 = query.getOrDefault("nextToken")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "nextToken", valid_773355
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
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773363: Call_ListPipelines_773351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_773363.validator(path, query, header, formData, body)
  let scheme = call_773363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773363.url(scheme.get, call_773363.host, call_773363.base,
                         call_773363.route, valid.getOrDefault("path"))
  result = hook(call_773363, url, valid)

proc call*(call_773364: Call_ListPipelines_773351; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_773365 = newJObject()
  add(query_773365, "maxResults", newJInt(maxResults))
  add(query_773365, "nextToken", newJString(nextToken))
  result = call_773364.call(nil, query_773365, nil, nil, nil)

var listPipelines* = Call_ListPipelines_773351(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_773352, base: "/",
    url: url_ListPipelines_773353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_773396 = ref object of OpenApiRestCall_772597
proc url_UpdateChannel_773398(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateChannel_773397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773399 = path.getOrDefault("channelName")
  valid_773399 = validateParameter(valid_773399, JString, required = true,
                                 default = nil)
  if valid_773399 != nil:
    section.add "channelName", valid_773399
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Content-Sha256", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Algorithm")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Algorithm", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Signature")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Signature", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-SignedHeaders", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Credential")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Credential", valid_773406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773408: Call_UpdateChannel_773396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_773408.validator(path, query, header, formData, body)
  let scheme = call_773408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773408.url(scheme.get, call_773408.host, call_773408.base,
                         call_773408.route, valid.getOrDefault("path"))
  result = hook(call_773408, url, valid)

proc call*(call_773409: Call_UpdateChannel_773396; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_773410 = newJObject()
  var body_773411 = newJObject()
  add(path_773410, "channelName", newJString(channelName))
  if body != nil:
    body_773411 = body
  result = call_773409.call(path_773410, nil, nil, nil, body_773411)

var updateChannel* = Call_UpdateChannel_773396(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_773397,
    base: "/", url: url_UpdateChannel_773398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_773380 = ref object of OpenApiRestCall_772597
proc url_DescribeChannel_773382(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeChannel_773381(path: JsonNode; query: JsonNode;
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
  var valid_773383 = path.getOrDefault("channelName")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "channelName", valid_773383
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response.
  section = newJObject()
  var valid_773384 = query.getOrDefault("includeStatistics")
  valid_773384 = validateParameter(valid_773384, JBool, required = false, default = nil)
  if valid_773384 != nil:
    section.add "includeStatistics", valid_773384
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Content-Sha256", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Algorithm")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Algorithm", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Signature")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Signature", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-SignedHeaders", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Credential")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Credential", valid_773391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773392: Call_DescribeChannel_773380; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_773392.validator(path, query, header, formData, body)
  let scheme = call_773392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773392.url(scheme.get, call_773392.host, call_773392.base,
                         call_773392.route, valid.getOrDefault("path"))
  result = hook(call_773392, url, valid)

proc call*(call_773393: Call_DescribeChannel_773380; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response.
  var path_773394 = newJObject()
  var query_773395 = newJObject()
  add(path_773394, "channelName", newJString(channelName))
  add(query_773395, "includeStatistics", newJBool(includeStatistics))
  result = call_773393.call(path_773394, query_773395, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_773380(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_773381,
    base: "/", url: url_DescribeChannel_773382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_773412 = ref object of OpenApiRestCall_772597
proc url_DeleteChannel_773414(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteChannel_773413(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773415 = path.getOrDefault("channelName")
  valid_773415 = validateParameter(valid_773415, JString, required = true,
                                 default = nil)
  if valid_773415 != nil:
    section.add "channelName", valid_773415
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
  var valid_773416 = header.getOrDefault("X-Amz-Date")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Date", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Security-Token")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Security-Token", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773423: Call_DeleteChannel_773412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_773423.validator(path, query, header, formData, body)
  let scheme = call_773423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773423.url(scheme.get, call_773423.host, call_773423.base,
                         call_773423.route, valid.getOrDefault("path"))
  result = hook(call_773423, url, valid)

proc call*(call_773424: Call_DeleteChannel_773412; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_773425 = newJObject()
  add(path_773425, "channelName", newJString(channelName))
  result = call_773424.call(path_773425, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_773412(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_773413,
    base: "/", url: url_DeleteChannel_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_773440 = ref object of OpenApiRestCall_772597
proc url_UpdateDataset_773442(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDataset_773441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773443 = path.getOrDefault("datasetName")
  valid_773443 = validateParameter(valid_773443, JString, required = true,
                                 default = nil)
  if valid_773443 != nil:
    section.add "datasetName", valid_773443
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
  var valid_773444 = header.getOrDefault("X-Amz-Date")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Date", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Security-Token")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Security-Token", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Content-Sha256", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Algorithm")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Algorithm", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Signature")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Signature", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-SignedHeaders", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Credential")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Credential", valid_773450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773452: Call_UpdateDataset_773440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_773452.validator(path, query, header, formData, body)
  let scheme = call_773452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773452.url(scheme.get, call_773452.host, call_773452.base,
                         call_773452.route, valid.getOrDefault("path"))
  result = hook(call_773452, url, valid)

proc call*(call_773453: Call_UpdateDataset_773440; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_773454 = newJObject()
  var body_773455 = newJObject()
  add(path_773454, "datasetName", newJString(datasetName))
  if body != nil:
    body_773455 = body
  result = call_773453.call(path_773454, nil, nil, nil, body_773455)

var updateDataset* = Call_UpdateDataset_773440(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_773441,
    base: "/", url: url_UpdateDataset_773442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_773426 = ref object of OpenApiRestCall_772597
proc url_DescribeDataset_773428(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDataset_773427(path: JsonNode; query: JsonNode;
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
  var valid_773429 = path.getOrDefault("datasetName")
  valid_773429 = validateParameter(valid_773429, JString, required = true,
                                 default = nil)
  if valid_773429 != nil:
    section.add "datasetName", valid_773429
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Content-Sha256", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Algorithm")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Algorithm", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Signature")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Signature", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-SignedHeaders", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Credential")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Credential", valid_773436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773437: Call_DescribeDataset_773426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_773437.validator(path, query, header, formData, body)
  let scheme = call_773437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773437.url(scheme.get, call_773437.host, call_773437.base,
                         call_773437.route, valid.getOrDefault("path"))
  result = hook(call_773437, url, valid)

proc call*(call_773438: Call_DescribeDataset_773426; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_773439 = newJObject()
  add(path_773439, "datasetName", newJString(datasetName))
  result = call_773438.call(path_773439, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_773426(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_773427,
    base: "/", url: url_DescribeDataset_773428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_773456 = ref object of OpenApiRestCall_772597
proc url_DeleteDataset_773458(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDataset_773457(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773459 = path.getOrDefault("datasetName")
  valid_773459 = validateParameter(valid_773459, JString, required = true,
                                 default = nil)
  if valid_773459 != nil:
    section.add "datasetName", valid_773459
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
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Content-Sha256", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Algorithm")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Algorithm", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Signature")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Signature", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-SignedHeaders", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Credential")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Credential", valid_773466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773467: Call_DeleteDataset_773456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_773467.validator(path, query, header, formData, body)
  let scheme = call_773467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773467.url(scheme.get, call_773467.host, call_773467.base,
                         call_773467.route, valid.getOrDefault("path"))
  result = hook(call_773467, url, valid)

proc call*(call_773468: Call_DeleteDataset_773456; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_773469 = newJObject()
  add(path_773469, "datasetName", newJString(datasetName))
  result = call_773468.call(path_773469, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_773456(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_773457,
    base: "/", url: url_DeleteDataset_773458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_773486 = ref object of OpenApiRestCall_772597
proc url_UpdateDatastore_773488(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDatastore_773487(path: JsonNode; query: JsonNode;
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
  var valid_773489 = path.getOrDefault("datastoreName")
  valid_773489 = validateParameter(valid_773489, JString, required = true,
                                 default = nil)
  if valid_773489 != nil:
    section.add "datastoreName", valid_773489
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Content-Sha256", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Algorithm")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Algorithm", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Signature")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Signature", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-SignedHeaders", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Credential")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Credential", valid_773496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773498: Call_UpdateDatastore_773486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_773498.validator(path, query, header, formData, body)
  let scheme = call_773498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773498.url(scheme.get, call_773498.host, call_773498.base,
                         call_773498.route, valid.getOrDefault("path"))
  result = hook(call_773498, url, valid)

proc call*(call_773499: Call_UpdateDatastore_773486; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_773500 = newJObject()
  var body_773501 = newJObject()
  add(path_773500, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_773501 = body
  result = call_773499.call(path_773500, nil, nil, nil, body_773501)

var updateDatastore* = Call_UpdateDatastore_773486(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_773487,
    base: "/", url: url_UpdateDatastore_773488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_773470 = ref object of OpenApiRestCall_772597
proc url_DescribeDatastore_773472(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDatastore_773471(path: JsonNode; query: JsonNode;
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
  var valid_773473 = path.getOrDefault("datastoreName")
  valid_773473 = validateParameter(valid_773473, JString, required = true,
                                 default = nil)
  if valid_773473 != nil:
    section.add "datastoreName", valid_773473
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the datastore is included in the response.
  section = newJObject()
  var valid_773474 = query.getOrDefault("includeStatistics")
  valid_773474 = validateParameter(valid_773474, JBool, required = false, default = nil)
  if valid_773474 != nil:
    section.add "includeStatistics", valid_773474
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
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Content-Sha256", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Algorithm")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Algorithm", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Signature")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Signature", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-SignedHeaders", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Credential")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Credential", valid_773481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773482: Call_DescribeDatastore_773470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_773482.validator(path, query, header, formData, body)
  let scheme = call_773482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773482.url(scheme.get, call_773482.host, call_773482.base,
                         call_773482.route, valid.getOrDefault("path"))
  result = hook(call_773482, url, valid)

proc call*(call_773483: Call_DescribeDatastore_773470; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the datastore is included in the response.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  var path_773484 = newJObject()
  var query_773485 = newJObject()
  add(query_773485, "includeStatistics", newJBool(includeStatistics))
  add(path_773484, "datastoreName", newJString(datastoreName))
  result = call_773483.call(path_773484, query_773485, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_773470(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_773471,
    base: "/", url: url_DescribeDatastore_773472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_773502 = ref object of OpenApiRestCall_772597
proc url_DeleteDatastore_773504(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datastoreName" in path, "`datastoreName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datastores/"),
               (kind: VariableSegment, value: "datastoreName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDatastore_773503(path: JsonNode; query: JsonNode;
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
  var valid_773505 = path.getOrDefault("datastoreName")
  valid_773505 = validateParameter(valid_773505, JString, required = true,
                                 default = nil)
  if valid_773505 != nil:
    section.add "datastoreName", valid_773505
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
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773513: Call_DeleteDatastore_773502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_773513.validator(path, query, header, formData, body)
  let scheme = call_773513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773513.url(scheme.get, call_773513.host, call_773513.base,
                         call_773513.route, valid.getOrDefault("path"))
  result = hook(call_773513, url, valid)

proc call*(call_773514: Call_DeleteDatastore_773502; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_773515 = newJObject()
  add(path_773515, "datastoreName", newJString(datastoreName))
  result = call_773514.call(path_773515, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_773502(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_773503,
    base: "/", url: url_DeleteDatastore_773504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_773530 = ref object of OpenApiRestCall_772597
proc url_UpdatePipeline_773532(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdatePipeline_773531(path: JsonNode; query: JsonNode;
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
  var valid_773533 = path.getOrDefault("pipelineName")
  valid_773533 = validateParameter(valid_773533, JString, required = true,
                                 default = nil)
  if valid_773533 != nil:
    section.add "pipelineName", valid_773533
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
  var valid_773534 = header.getOrDefault("X-Amz-Date")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Date", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Security-Token")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Security-Token", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Content-Sha256", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Algorithm")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Algorithm", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Signature")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Signature", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-SignedHeaders", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Credential")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Credential", valid_773540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773542: Call_UpdatePipeline_773530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_773542.validator(path, query, header, formData, body)
  let scheme = call_773542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773542.url(scheme.get, call_773542.host, call_773542.base,
                         call_773542.route, valid.getOrDefault("path"))
  result = hook(call_773542, url, valid)

proc call*(call_773543: Call_UpdatePipeline_773530; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_773544 = newJObject()
  var body_773545 = newJObject()
  add(path_773544, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_773545 = body
  result = call_773543.call(path_773544, nil, nil, nil, body_773545)

var updatePipeline* = Call_UpdatePipeline_773530(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_773531,
    base: "/", url: url_UpdatePipeline_773532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_773516 = ref object of OpenApiRestCall_772597
proc url_DescribePipeline_773518(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribePipeline_773517(path: JsonNode; query: JsonNode;
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
  var valid_773519 = path.getOrDefault("pipelineName")
  valid_773519 = validateParameter(valid_773519, JString, required = true,
                                 default = nil)
  if valid_773519 != nil:
    section.add "pipelineName", valid_773519
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
  var valid_773520 = header.getOrDefault("X-Amz-Date")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Date", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Security-Token")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Security-Token", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Content-Sha256", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Algorithm")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Algorithm", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Signature")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Signature", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-SignedHeaders", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Credential")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Credential", valid_773526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773527: Call_DescribePipeline_773516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_773527.validator(path, query, header, formData, body)
  let scheme = call_773527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773527.url(scheme.get, call_773527.host, call_773527.base,
                         call_773527.route, valid.getOrDefault("path"))
  result = hook(call_773527, url, valid)

proc call*(call_773528: Call_DescribePipeline_773516; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_773529 = newJObject()
  add(path_773529, "pipelineName", newJString(pipelineName))
  result = call_773528.call(path_773529, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_773516(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_773517,
    base: "/", url: url_DescribePipeline_773518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_773546 = ref object of OpenApiRestCall_772597
proc url_DeletePipeline_773548(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePipeline_773547(path: JsonNode; query: JsonNode;
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
  var valid_773549 = path.getOrDefault("pipelineName")
  valid_773549 = validateParameter(valid_773549, JString, required = true,
                                 default = nil)
  if valid_773549 != nil:
    section.add "pipelineName", valid_773549
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Content-Sha256", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Algorithm")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Algorithm", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Signature")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Signature", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-SignedHeaders", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Credential")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Credential", valid_773556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773557: Call_DeletePipeline_773546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_773557.validator(path, query, header, formData, body)
  let scheme = call_773557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773557.url(scheme.get, call_773557.host, call_773557.base,
                         call_773557.route, valid.getOrDefault("path"))
  result = hook(call_773557, url, valid)

proc call*(call_773558: Call_DeletePipeline_773546; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_773559 = newJObject()
  add(path_773559, "pipelineName", newJString(pipelineName))
  result = call_773558.call(path_773559, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_773546(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_773547,
    base: "/", url: url_DeletePipeline_773548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_773572 = ref object of OpenApiRestCall_772597
proc url_PutLoggingOptions_773574(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutLoggingOptions_773573(path: JsonNode; query: JsonNode;
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
  var valid_773575 = header.getOrDefault("X-Amz-Date")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Date", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Security-Token")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Security-Token", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Content-Sha256", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Algorithm")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Algorithm", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Signature")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Signature", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-SignedHeaders", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Credential")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Credential", valid_773581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773583: Call_PutLoggingOptions_773572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_773583.validator(path, query, header, formData, body)
  let scheme = call_773583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773583.url(scheme.get, call_773583.host, call_773583.base,
                         call_773583.route, valid.getOrDefault("path"))
  result = hook(call_773583, url, valid)

proc call*(call_773584: Call_PutLoggingOptions_773572; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_773585 = newJObject()
  if body != nil:
    body_773585 = body
  result = call_773584.call(nil, nil, nil, nil, body_773585)

var putLoggingOptions* = Call_PutLoggingOptions_773572(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_773573, base: "/",
    url: url_PutLoggingOptions_773574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_773560 = ref object of OpenApiRestCall_772597
proc url_DescribeLoggingOptions_773562(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLoggingOptions_773561(path: JsonNode; query: JsonNode;
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
  var valid_773563 = header.getOrDefault("X-Amz-Date")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Date", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Security-Token")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Security-Token", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Content-Sha256", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Algorithm")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Algorithm", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Signature")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Signature", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-SignedHeaders", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Credential")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Credential", valid_773569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773570: Call_DescribeLoggingOptions_773560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_773570.validator(path, query, header, formData, body)
  let scheme = call_773570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773570.url(scheme.get, call_773570.host, call_773570.base,
                         call_773570.route, valid.getOrDefault("path"))
  result = hook(call_773570, url, valid)

proc call*(call_773571: Call_DescribeLoggingOptions_773560): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_773571.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_773560(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_773561, base: "/",
    url: url_DescribeLoggingOptions_773562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_773586 = ref object of OpenApiRestCall_772597
proc url_ListDatasetContents_773588(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "datasetName" in path, "`datasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/datasets/"),
               (kind: VariableSegment, value: "datasetName"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDatasetContents_773587(path: JsonNode; query: JsonNode;
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
  var valid_773589 = path.getOrDefault("datasetName")
  valid_773589 = validateParameter(valid_773589, JString, required = true,
                                 default = nil)
  if valid_773589 != nil:
    section.add "datasetName", valid_773589
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
  var valid_773590 = query.getOrDefault("scheduledOnOrAfter")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "scheduledOnOrAfter", valid_773590
  var valid_773591 = query.getOrDefault("scheduledBefore")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "scheduledBefore", valid_773591
  var valid_773592 = query.getOrDefault("maxResults")
  valid_773592 = validateParameter(valid_773592, JInt, required = false, default = nil)
  if valid_773592 != nil:
    section.add "maxResults", valid_773592
  var valid_773593 = query.getOrDefault("nextToken")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "nextToken", valid_773593
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
  var valid_773594 = header.getOrDefault("X-Amz-Date")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Date", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Security-Token")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Security-Token", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Content-Sha256", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Algorithm")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Algorithm", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Signature")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Signature", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-SignedHeaders", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Credential")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Credential", valid_773600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_ListDatasetContents_773586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_ListDatasetContents_773586; datasetName: string;
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
  var path_773603 = newJObject()
  var query_773604 = newJObject()
  add(query_773604, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(query_773604, "scheduledBefore", newJString(scheduledBefore))
  add(query_773604, "maxResults", newJInt(maxResults))
  add(query_773604, "nextToken", newJString(nextToken))
  add(path_773603, "datasetName", newJString(datasetName))
  result = call_773602.call(path_773603, query_773604, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_773586(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_773587, base: "/",
    url: url_ListDatasetContents_773588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773619 = ref object of OpenApiRestCall_772597
proc url_TagResource_773621(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773620(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773622 = query.getOrDefault("resourceArn")
  valid_773622 = validateParameter(valid_773622, JString, required = true,
                                 default = nil)
  if valid_773622 != nil:
    section.add "resourceArn", valid_773622
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
  var valid_773623 = header.getOrDefault("X-Amz-Date")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Date", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Security-Token")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Security-Token", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Content-Sha256", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Algorithm")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Algorithm", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Signature")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Signature", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-SignedHeaders", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Credential")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Credential", valid_773629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773631: Call_TagResource_773619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_773631.validator(path, query, header, formData, body)
  let scheme = call_773631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773631.url(scheme.get, call_773631.host, call_773631.base,
                         call_773631.route, valid.getOrDefault("path"))
  result = hook(call_773631, url, valid)

proc call*(call_773632: Call_TagResource_773619; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  ##   body: JObject (required)
  var query_773633 = newJObject()
  var body_773634 = newJObject()
  add(query_773633, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_773634 = body
  result = call_773632.call(nil, query_773633, nil, nil, body_773634)

var tagResource* = Call_TagResource_773619(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_773620,
                                        base: "/", url: url_TagResource_773621,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773605 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773607(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773606(path: JsonNode; query: JsonNode;
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
  var valid_773608 = query.getOrDefault("resourceArn")
  valid_773608 = validateParameter(valid_773608, JString, required = true,
                                 default = nil)
  if valid_773608 != nil:
    section.add "resourceArn", valid_773608
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
  var valid_773609 = header.getOrDefault("X-Amz-Date")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Date", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Security-Token")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Security-Token", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Content-Sha256", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Algorithm")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Algorithm", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Signature")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Signature", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-SignedHeaders", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Credential")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Credential", valid_773615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773616: Call_ListTagsForResource_773605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_773616.validator(path, query, header, formData, body)
  let scheme = call_773616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773616.url(scheme.get, call_773616.host, call_773616.base,
                         call_773616.route, valid.getOrDefault("path"))
  result = hook(call_773616, url, valid)

proc call*(call_773617: Call_ListTagsForResource_773605; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_773618 = newJObject()
  add(query_773618, "resourceArn", newJString(resourceArn))
  result = call_773617.call(nil, query_773618, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773605(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_773606, base: "/",
    url: url_ListTagsForResource_773607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_773635 = ref object of OpenApiRestCall_772597
proc url_RunPipelineActivity_773637(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RunPipelineActivity_773636(path: JsonNode; query: JsonNode;
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
  var valid_773638 = header.getOrDefault("X-Amz-Date")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Date", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Security-Token")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Security-Token", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Content-Sha256", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Algorithm")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Algorithm", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Signature")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Signature", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-SignedHeaders", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Credential")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Credential", valid_773644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773646: Call_RunPipelineActivity_773635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_773646.validator(path, query, header, formData, body)
  let scheme = call_773646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773646.url(scheme.get, call_773646.host, call_773646.base,
                         call_773646.route, valid.getOrDefault("path"))
  result = hook(call_773646, url, valid)

proc call*(call_773647: Call_RunPipelineActivity_773635; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_773648 = newJObject()
  if body != nil:
    body_773648 = body
  result = call_773647.call(nil, nil, nil, nil, body_773648)

var runPipelineActivity* = Call_RunPipelineActivity_773635(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_773636, base: "/",
    url: url_RunPipelineActivity_773637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_773649 = ref object of OpenApiRestCall_772597
proc url_SampleChannelData_773651(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelName" in path, "`channelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "channelName"),
               (kind: ConstantSegment, value: "/sample")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SampleChannelData_773650(path: JsonNode; query: JsonNode;
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
  var valid_773652 = path.getOrDefault("channelName")
  valid_773652 = validateParameter(valid_773652, JString, required = true,
                                 default = nil)
  if valid_773652 != nil:
    section.add "channelName", valid_773652
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_773653 = query.getOrDefault("endTime")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "endTime", valid_773653
  var valid_773654 = query.getOrDefault("maxMessages")
  valid_773654 = validateParameter(valid_773654, JInt, required = false, default = nil)
  if valid_773654 != nil:
    section.add "maxMessages", valid_773654
  var valid_773655 = query.getOrDefault("startTime")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "startTime", valid_773655
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
  var valid_773656 = header.getOrDefault("X-Amz-Date")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Date", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Security-Token")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Security-Token", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Signature")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Signature", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-SignedHeaders", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Credential")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Credential", valid_773662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773663: Call_SampleChannelData_773649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_773663.validator(path, query, header, formData, body)
  let scheme = call_773663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773663.url(scheme.get, call_773663.host, call_773663.base,
                         call_773663.route, valid.getOrDefault("path"))
  result = hook(call_773663, url, valid)

proc call*(call_773664: Call_SampleChannelData_773649; channelName: string;
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
  var path_773665 = newJObject()
  var query_773666 = newJObject()
  add(query_773666, "endTime", newJString(endTime))
  add(query_773666, "maxMessages", newJInt(maxMessages))
  add(path_773665, "channelName", newJString(channelName))
  add(query_773666, "startTime", newJString(startTime))
  result = call_773664.call(path_773665, query_773666, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_773649(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_773650, base: "/",
    url: url_SampleChannelData_773651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_773667 = ref object of OpenApiRestCall_772597
proc url_StartPipelineReprocessing_773669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/pipelines/"),
               (kind: VariableSegment, value: "pipelineName"),
               (kind: ConstantSegment, value: "/reprocessing")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StartPipelineReprocessing_773668(path: JsonNode; query: JsonNode;
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
  var valid_773670 = path.getOrDefault("pipelineName")
  valid_773670 = validateParameter(valid_773670, JString, required = true,
                                 default = nil)
  if valid_773670 != nil:
    section.add "pipelineName", valid_773670
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
  var valid_773671 = header.getOrDefault("X-Amz-Date")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Date", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Security-Token")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Security-Token", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Content-Sha256", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Algorithm")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Algorithm", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Signature")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Signature", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-SignedHeaders", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Credential")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Credential", valid_773677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773679: Call_StartPipelineReprocessing_773667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_773679.validator(path, query, header, formData, body)
  let scheme = call_773679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773679.url(scheme.get, call_773679.host, call_773679.base,
                         call_773679.route, valid.getOrDefault("path"))
  result = hook(call_773679, url, valid)

proc call*(call_773680: Call_StartPipelineReprocessing_773667;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_773681 = newJObject()
  var body_773682 = newJObject()
  add(path_773681, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_773682 = body
  result = call_773680.call(path_773681, nil, nil, nil, body_773682)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_773667(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_773668, base: "/",
    url: url_StartPipelineReprocessing_773669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773683 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773685(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773684(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773686 = query.getOrDefault("resourceArn")
  valid_773686 = validateParameter(valid_773686, JString, required = true,
                                 default = nil)
  if valid_773686 != nil:
    section.add "resourceArn", valid_773686
  var valid_773687 = query.getOrDefault("tagKeys")
  valid_773687 = validateParameter(valid_773687, JArray, required = true, default = nil)
  if valid_773687 != nil:
    section.add "tagKeys", valid_773687
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
  var valid_773688 = header.getOrDefault("X-Amz-Date")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Date", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Security-Token")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Security-Token", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Content-Sha256", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-Algorithm")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Algorithm", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Signature")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Signature", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-SignedHeaders", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Credential")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Credential", valid_773694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773695: Call_UntagResource_773683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_773695.validator(path, query, header, formData, body)
  let scheme = call_773695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773695.url(scheme.get, call_773695.host, call_773695.base,
                         call_773695.route, valid.getOrDefault("path"))
  result = hook(call_773695, url, valid)

proc call*(call_773696: Call_UntagResource_773683; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var query_773697 = newJObject()
  add(query_773697, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_773697.add "tagKeys", tagKeys
  result = call_773696.call(nil, query_773697, nil, nil, nil)

var untagResource* = Call_UntagResource_773683(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_773684,
    base: "/", url: url_UntagResource_773685, schemes: {Scheme.Https, Scheme.Http})
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
