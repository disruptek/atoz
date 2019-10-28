
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_590703 = ref object of OpenApiRestCall_590364
proc url_BatchPutMessage_590705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchPutMessage_590704(path: JsonNode; query: JsonNode;
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
  var valid_590817 = header.getOrDefault("X-Amz-Signature")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "X-Amz-Signature", valid_590817
  var valid_590818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "X-Amz-Content-Sha256", valid_590818
  var valid_590819 = header.getOrDefault("X-Amz-Date")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Date", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Credential")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Credential", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Security-Token")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Security-Token", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Algorithm")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Algorithm", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-SignedHeaders", valid_590823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590847: Call_BatchPutMessage_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_590847.validator(path, query, header, formData, body)
  let scheme = call_590847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590847.url(scheme.get, call_590847.host, call_590847.base,
                         call_590847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590847, url, valid)

proc call*(call_590918: Call_BatchPutMessage_590703; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_590919 = newJObject()
  if body != nil:
    body_590919 = body
  result = call_590918.call(nil, nil, nil, nil, body_590919)

var batchPutMessage* = Call_BatchPutMessage_590703(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_590704, base: "/",
    url: url_BatchPutMessage_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_590958 = ref object of OpenApiRestCall_590364
proc url_CancelPipelineReprocessing_590960(protocol: Scheme; host: string;
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

proc validate_CancelPipelineReprocessing_590959(path: JsonNode; query: JsonNode;
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
  var valid_590975 = path.getOrDefault("reprocessingId")
  valid_590975 = validateParameter(valid_590975, JString, required = true,
                                 default = nil)
  if valid_590975 != nil:
    section.add "reprocessingId", valid_590975
  var valid_590976 = path.getOrDefault("pipelineName")
  valid_590976 = validateParameter(valid_590976, JString, required = true,
                                 default = nil)
  if valid_590976 != nil:
    section.add "pipelineName", valid_590976
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
  var valid_590977 = header.getOrDefault("X-Amz-Signature")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Signature", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Content-Sha256", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Date")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Date", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Credential")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Credential", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Security-Token")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Security-Token", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Algorithm")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Algorithm", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-SignedHeaders", valid_590983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_CancelPipelineReprocessing_590958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_CancelPipelineReprocessing_590958;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_590986 = newJObject()
  add(path_590986, "reprocessingId", newJString(reprocessingId))
  add(path_590986, "pipelineName", newJString(pipelineName))
  result = call_590985.call(path_590986, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_590958(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_590959, base: "/",
    url: url_CancelPipelineReprocessing_590960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_591003 = ref object of OpenApiRestCall_590364
proc url_CreateChannel_591005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateChannel_591004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateChannel_591003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateChannel_591003; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var createChannel* = Call_CreateChannel_591003(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_591004, base: "/",
    url: url_CreateChannel_591005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_590988 = ref object of OpenApiRestCall_590364
proc url_ListChannels_590990(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChannels_590989(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590991 = query.getOrDefault("nextToken")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "nextToken", valid_590991
  var valid_590992 = query.getOrDefault("maxResults")
  valid_590992 = validateParameter(valid_590992, JInt, required = false, default = nil)
  if valid_590992 != nil:
    section.add "maxResults", valid_590992
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
  var valid_590993 = header.getOrDefault("X-Amz-Signature")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Signature", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Content-Sha256", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Date")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Date", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Credential")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Credential", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Security-Token")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Security-Token", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Algorithm")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Algorithm", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-SignedHeaders", valid_590999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591000: Call_ListChannels_590988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_591000.validator(path, query, header, formData, body)
  let scheme = call_591000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591000.url(scheme.get, call_591000.host, call_591000.base,
                         call_591000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591000, url, valid)

proc call*(call_591001: Call_ListChannels_590988; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_591002 = newJObject()
  add(query_591002, "nextToken", newJString(nextToken))
  add(query_591002, "maxResults", newJInt(maxResults))
  result = call_591001.call(nil, query_591002, nil, nil, nil)

var listChannels* = Call_ListChannels_590988(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_590989, base: "/",
    url: url_ListChannels_590990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_591032 = ref object of OpenApiRestCall_590364
proc url_CreateDataset_591034(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataset_591033(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591035 = header.getOrDefault("X-Amz-Signature")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-Signature", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Content-Sha256", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Date")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Date", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Credential")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Credential", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Security-Token")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Security-Token", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Algorithm")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Algorithm", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-SignedHeaders", valid_591041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591043: Call_CreateDataset_591032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_591043.validator(path, query, header, formData, body)
  let scheme = call_591043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591043.url(scheme.get, call_591043.host, call_591043.base,
                         call_591043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591043, url, valid)

proc call*(call_591044: Call_CreateDataset_591032; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_591045 = newJObject()
  if body != nil:
    body_591045 = body
  result = call_591044.call(nil, nil, nil, nil, body_591045)

var createDataset* = Call_CreateDataset_591032(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_591033, base: "/",
    url: url_CreateDataset_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_591017 = ref object of OpenApiRestCall_590364
proc url_ListDatasets_591019(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatasets_591018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591020 = query.getOrDefault("nextToken")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "nextToken", valid_591020
  var valid_591021 = query.getOrDefault("maxResults")
  valid_591021 = validateParameter(valid_591021, JInt, required = false, default = nil)
  if valid_591021 != nil:
    section.add "maxResults", valid_591021
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
  var valid_591022 = header.getOrDefault("X-Amz-Signature")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Signature", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Content-Sha256", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Date")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Date", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Credential")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Credential", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Security-Token")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Security-Token", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Algorithm")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Algorithm", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-SignedHeaders", valid_591028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_ListDatasets_591017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_ListDatasets_591017; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_591031 = newJObject()
  add(query_591031, "nextToken", newJString(nextToken))
  add(query_591031, "maxResults", newJInt(maxResults))
  result = call_591030.call(nil, query_591031, nil, nil, nil)

var listDatasets* = Call_ListDatasets_591017(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_591018, base: "/",
    url: url_ListDatasets_591019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_591062 = ref object of OpenApiRestCall_590364
proc url_CreateDatasetContent_591064(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatasetContent_591063(path: JsonNode; query: JsonNode;
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
  var valid_591065 = path.getOrDefault("datasetName")
  valid_591065 = validateParameter(valid_591065, JString, required = true,
                                 default = nil)
  if valid_591065 != nil:
    section.add "datasetName", valid_591065
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
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591073: Call_CreateDatasetContent_591062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_591073.validator(path, query, header, formData, body)
  let scheme = call_591073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591073.url(scheme.get, call_591073.host, call_591073.base,
                         call_591073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591073, url, valid)

proc call*(call_591074: Call_CreateDatasetContent_591062; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_591075 = newJObject()
  add(path_591075, "datasetName", newJString(datasetName))
  result = call_591074.call(path_591075, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_591062(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_591063, base: "/",
    url: url_CreateDatasetContent_591064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_591046 = ref object of OpenApiRestCall_590364
proc url_GetDatasetContent_591048(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatasetContent_591047(path: JsonNode; query: JsonNode;
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
  var valid_591049 = path.getOrDefault("datasetName")
  valid_591049 = validateParameter(valid_591049, JString, required = true,
                                 default = nil)
  if valid_591049 != nil:
    section.add "datasetName", valid_591049
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_591050 = query.getOrDefault("versionId")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "versionId", valid_591050
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
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591058: Call_GetDatasetContent_591046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_591058.validator(path, query, header, formData, body)
  let scheme = call_591058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591058.url(scheme.get, call_591058.host, call_591058.base,
                         call_591058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591058, url, valid)

proc call*(call_591059: Call_GetDatasetContent_591046; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_591060 = newJObject()
  var query_591061 = newJObject()
  add(query_591061, "versionId", newJString(versionId))
  add(path_591060, "datasetName", newJString(datasetName))
  result = call_591059.call(path_591060, query_591061, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_591046(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_591047, base: "/",
    url: url_GetDatasetContent_591048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_591076 = ref object of OpenApiRestCall_590364
proc url_DeleteDatasetContent_591078(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatasetContent_591077(path: JsonNode; query: JsonNode;
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
  var valid_591079 = path.getOrDefault("datasetName")
  valid_591079 = validateParameter(valid_591079, JString, required = true,
                                 default = nil)
  if valid_591079 != nil:
    section.add "datasetName", valid_591079
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_591080 = query.getOrDefault("versionId")
  valid_591080 = validateParameter(valid_591080, JString, required = false,
                                 default = nil)
  if valid_591080 != nil:
    section.add "versionId", valid_591080
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
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591088: Call_DeleteDatasetContent_591076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_591088.validator(path, query, header, formData, body)
  let scheme = call_591088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591088.url(scheme.get, call_591088.host, call_591088.base,
                         call_591088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591088, url, valid)

proc call*(call_591089: Call_DeleteDatasetContent_591076; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_591090 = newJObject()
  var query_591091 = newJObject()
  add(query_591091, "versionId", newJString(versionId))
  add(path_591090, "datasetName", newJString(datasetName))
  result = call_591089.call(path_591090, query_591091, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_591076(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_591077, base: "/",
    url: url_DeleteDatasetContent_591078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_591107 = ref object of OpenApiRestCall_590364
proc url_CreateDatastore_591109(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatastore_591108(path: JsonNode; query: JsonNode;
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
  var valid_591110 = header.getOrDefault("X-Amz-Signature")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Signature", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Content-Sha256", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Date")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Date", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Credential")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Credential", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Security-Token")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Security-Token", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Algorithm")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Algorithm", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-SignedHeaders", valid_591116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591118: Call_CreateDatastore_591107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_591118.validator(path, query, header, formData, body)
  let scheme = call_591118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591118.url(scheme.get, call_591118.host, call_591118.base,
                         call_591118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591118, url, valid)

proc call*(call_591119: Call_CreateDatastore_591107; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_591120 = newJObject()
  if body != nil:
    body_591120 = body
  result = call_591119.call(nil, nil, nil, nil, body_591120)

var createDatastore* = Call_CreateDatastore_591107(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_591108, base: "/",
    url: url_CreateDatastore_591109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_591092 = ref object of OpenApiRestCall_590364
proc url_ListDatastores_591094(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatastores_591093(path: JsonNode; query: JsonNode;
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
  var valid_591095 = query.getOrDefault("nextToken")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "nextToken", valid_591095
  var valid_591096 = query.getOrDefault("maxResults")
  valid_591096 = validateParameter(valid_591096, JInt, required = false, default = nil)
  if valid_591096 != nil:
    section.add "maxResults", valid_591096
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
  var valid_591097 = header.getOrDefault("X-Amz-Signature")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Signature", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Content-Sha256", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Date")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Date", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Credential")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Credential", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Security-Token")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Security-Token", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Algorithm")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Algorithm", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-SignedHeaders", valid_591103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_ListDatastores_591092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_ListDatastores_591092; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_591106 = newJObject()
  add(query_591106, "nextToken", newJString(nextToken))
  add(query_591106, "maxResults", newJInt(maxResults))
  result = call_591105.call(nil, query_591106, nil, nil, nil)

var listDatastores* = Call_ListDatastores_591092(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_591093, base: "/",
    url: url_ListDatastores_591094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_591136 = ref object of OpenApiRestCall_590364
proc url_CreatePipeline_591138(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_591137(path: JsonNode; query: JsonNode;
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
  var valid_591139 = header.getOrDefault("X-Amz-Signature")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "X-Amz-Signature", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Content-Sha256", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Date")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Date", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Credential")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Credential", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Security-Token")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Security-Token", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Algorithm")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Algorithm", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-SignedHeaders", valid_591145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591147: Call_CreatePipeline_591136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_591147.validator(path, query, header, formData, body)
  let scheme = call_591147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591147.url(scheme.get, call_591147.host, call_591147.base,
                         call_591147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591147, url, valid)

proc call*(call_591148: Call_CreatePipeline_591136; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_591149 = newJObject()
  if body != nil:
    body_591149 = body
  result = call_591148.call(nil, nil, nil, nil, body_591149)

var createPipeline* = Call_CreatePipeline_591136(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_591137, base: "/",
    url: url_CreatePipeline_591138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_591121 = ref object of OpenApiRestCall_590364
proc url_ListPipelines_591123(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_591122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591124 = query.getOrDefault("nextToken")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "nextToken", valid_591124
  var valid_591125 = query.getOrDefault("maxResults")
  valid_591125 = validateParameter(valid_591125, JInt, required = false, default = nil)
  if valid_591125 != nil:
    section.add "maxResults", valid_591125
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
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591133: Call_ListPipelines_591121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_591133.validator(path, query, header, formData, body)
  let scheme = call_591133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591133.url(scheme.get, call_591133.host, call_591133.base,
                         call_591133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591133, url, valid)

proc call*(call_591134: Call_ListPipelines_591121; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_591135 = newJObject()
  add(query_591135, "nextToken", newJString(nextToken))
  add(query_591135, "maxResults", newJInt(maxResults))
  result = call_591134.call(nil, query_591135, nil, nil, nil)

var listPipelines* = Call_ListPipelines_591121(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_591122, base: "/",
    url: url_ListPipelines_591123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_591166 = ref object of OpenApiRestCall_590364
proc url_UpdateChannel_591168(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_591167(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591169 = path.getOrDefault("channelName")
  valid_591169 = validateParameter(valid_591169, JString, required = true,
                                 default = nil)
  if valid_591169 != nil:
    section.add "channelName", valid_591169
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
  var valid_591170 = header.getOrDefault("X-Amz-Signature")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Signature", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Content-Sha256", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Date")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Date", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Credential")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Credential", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Security-Token")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Security-Token", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Algorithm")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Algorithm", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-SignedHeaders", valid_591176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591178: Call_UpdateChannel_591166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_591178.validator(path, query, header, formData, body)
  let scheme = call_591178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591178.url(scheme.get, call_591178.host, call_591178.base,
                         call_591178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591178, url, valid)

proc call*(call_591179: Call_UpdateChannel_591166; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_591180 = newJObject()
  var body_591181 = newJObject()
  add(path_591180, "channelName", newJString(channelName))
  if body != nil:
    body_591181 = body
  result = call_591179.call(path_591180, nil, nil, nil, body_591181)

var updateChannel* = Call_UpdateChannel_591166(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_591167,
    base: "/", url: url_UpdateChannel_591168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_591150 = ref object of OpenApiRestCall_590364
proc url_DescribeChannel_591152(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_591151(path: JsonNode; query: JsonNode;
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
  var valid_591153 = path.getOrDefault("channelName")
  valid_591153 = validateParameter(valid_591153, JString, required = true,
                                 default = nil)
  if valid_591153 != nil:
    section.add "channelName", valid_591153
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_591154 = query.getOrDefault("includeStatistics")
  valid_591154 = validateParameter(valid_591154, JBool, required = false, default = nil)
  if valid_591154 != nil:
    section.add "includeStatistics", valid_591154
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
  var valid_591155 = header.getOrDefault("X-Amz-Signature")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Signature", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Content-Sha256", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Date")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Date", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Credential")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Credential", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Security-Token")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Security-Token", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Algorithm")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Algorithm", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-SignedHeaders", valid_591161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591162: Call_DescribeChannel_591150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_591162.validator(path, query, header, formData, body)
  let scheme = call_591162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591162.url(scheme.get, call_591162.host, call_591162.base,
                         call_591162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591162, url, valid)

proc call*(call_591163: Call_DescribeChannel_591150; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  var path_591164 = newJObject()
  var query_591165 = newJObject()
  add(path_591164, "channelName", newJString(channelName))
  add(query_591165, "includeStatistics", newJBool(includeStatistics))
  result = call_591163.call(path_591164, query_591165, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_591150(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_591151,
    base: "/", url: url_DescribeChannel_591152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_591182 = ref object of OpenApiRestCall_590364
proc url_DeleteChannel_591184(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_591183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591185 = path.getOrDefault("channelName")
  valid_591185 = validateParameter(valid_591185, JString, required = true,
                                 default = nil)
  if valid_591185 != nil:
    section.add "channelName", valid_591185
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
  var valid_591186 = header.getOrDefault("X-Amz-Signature")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Signature", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Content-Sha256", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Date")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Date", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Credential")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Credential", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Security-Token")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Security-Token", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Algorithm")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Algorithm", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-SignedHeaders", valid_591192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591193: Call_DeleteChannel_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_591193.validator(path, query, header, formData, body)
  let scheme = call_591193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591193.url(scheme.get, call_591193.host, call_591193.base,
                         call_591193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591193, url, valid)

proc call*(call_591194: Call_DeleteChannel_591182; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_591195 = newJObject()
  add(path_591195, "channelName", newJString(channelName))
  result = call_591194.call(path_591195, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_591182(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_591183,
    base: "/", url: url_DeleteChannel_591184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_591210 = ref object of OpenApiRestCall_590364
proc url_UpdateDataset_591212(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataset_591211(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591213 = path.getOrDefault("datasetName")
  valid_591213 = validateParameter(valid_591213, JString, required = true,
                                 default = nil)
  if valid_591213 != nil:
    section.add "datasetName", valid_591213
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
  var valid_591214 = header.getOrDefault("X-Amz-Signature")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-Signature", valid_591214
  var valid_591215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "X-Amz-Content-Sha256", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Date")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Date", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Credential")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Credential", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Security-Token")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Security-Token", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Algorithm")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Algorithm", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-SignedHeaders", valid_591220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591222: Call_UpdateDataset_591210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_591222.validator(path, query, header, formData, body)
  let scheme = call_591222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591222.url(scheme.get, call_591222.host, call_591222.base,
                         call_591222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591222, url, valid)

proc call*(call_591223: Call_UpdateDataset_591210; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_591224 = newJObject()
  var body_591225 = newJObject()
  add(path_591224, "datasetName", newJString(datasetName))
  if body != nil:
    body_591225 = body
  result = call_591223.call(path_591224, nil, nil, nil, body_591225)

var updateDataset* = Call_UpdateDataset_591210(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_591211,
    base: "/", url: url_UpdateDataset_591212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_591196 = ref object of OpenApiRestCall_590364
proc url_DescribeDataset_591198(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_591197(path: JsonNode; query: JsonNode;
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
  var valid_591199 = path.getOrDefault("datasetName")
  valid_591199 = validateParameter(valid_591199, JString, required = true,
                                 default = nil)
  if valid_591199 != nil:
    section.add "datasetName", valid_591199
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
  var valid_591200 = header.getOrDefault("X-Amz-Signature")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Signature", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Content-Sha256", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Date")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Date", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Credential")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Credential", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Security-Token")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Security-Token", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Algorithm")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Algorithm", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-SignedHeaders", valid_591206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591207: Call_DescribeDataset_591196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_591207.validator(path, query, header, formData, body)
  let scheme = call_591207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591207.url(scheme.get, call_591207.host, call_591207.base,
                         call_591207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591207, url, valid)

proc call*(call_591208: Call_DescribeDataset_591196; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_591209 = newJObject()
  add(path_591209, "datasetName", newJString(datasetName))
  result = call_591208.call(path_591209, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_591196(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_591197,
    base: "/", url: url_DescribeDataset_591198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_591226 = ref object of OpenApiRestCall_590364
proc url_DeleteDataset_591228(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_591227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591229 = path.getOrDefault("datasetName")
  valid_591229 = validateParameter(valid_591229, JString, required = true,
                                 default = nil)
  if valid_591229 != nil:
    section.add "datasetName", valid_591229
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
  var valid_591230 = header.getOrDefault("X-Amz-Signature")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Signature", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Content-Sha256", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Date")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Date", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Credential")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Credential", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-Security-Token")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-Security-Token", valid_591234
  var valid_591235 = header.getOrDefault("X-Amz-Algorithm")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "X-Amz-Algorithm", valid_591235
  var valid_591236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-SignedHeaders", valid_591236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591237: Call_DeleteDataset_591226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_591237.validator(path, query, header, formData, body)
  let scheme = call_591237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591237.url(scheme.get, call_591237.host, call_591237.base,
                         call_591237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591237, url, valid)

proc call*(call_591238: Call_DeleteDataset_591226; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_591239 = newJObject()
  add(path_591239, "datasetName", newJString(datasetName))
  result = call_591238.call(path_591239, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_591226(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_591227,
    base: "/", url: url_DeleteDataset_591228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_591256 = ref object of OpenApiRestCall_590364
proc url_UpdateDatastore_591258(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatastore_591257(path: JsonNode; query: JsonNode;
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
  var valid_591259 = path.getOrDefault("datastoreName")
  valid_591259 = validateParameter(valid_591259, JString, required = true,
                                 default = nil)
  if valid_591259 != nil:
    section.add "datastoreName", valid_591259
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
  var valid_591260 = header.getOrDefault("X-Amz-Signature")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Signature", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Content-Sha256", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Date")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Date", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Credential")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Credential", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Security-Token")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Security-Token", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Algorithm")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Algorithm", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-SignedHeaders", valid_591266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591268: Call_UpdateDatastore_591256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_591268.validator(path, query, header, formData, body)
  let scheme = call_591268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591268.url(scheme.get, call_591268.host, call_591268.base,
                         call_591268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591268, url, valid)

proc call*(call_591269: Call_UpdateDatastore_591256; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_591270 = newJObject()
  var body_591271 = newJObject()
  add(path_591270, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_591271 = body
  result = call_591269.call(path_591270, nil, nil, nil, body_591271)

var updateDatastore* = Call_UpdateDatastore_591256(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_591257,
    base: "/", url: url_UpdateDatastore_591258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_591240 = ref object of OpenApiRestCall_590364
proc url_DescribeDatastore_591242(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDatastore_591241(path: JsonNode; query: JsonNode;
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
  var valid_591243 = path.getOrDefault("datastoreName")
  valid_591243 = validateParameter(valid_591243, JString, required = true,
                                 default = nil)
  if valid_591243 != nil:
    section.add "datastoreName", valid_591243
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_591244 = query.getOrDefault("includeStatistics")
  valid_591244 = validateParameter(valid_591244, JBool, required = false, default = nil)
  if valid_591244 != nil:
    section.add "includeStatistics", valid_591244
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
  var valid_591245 = header.getOrDefault("X-Amz-Signature")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Signature", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Content-Sha256", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Date")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Date", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Credential")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Credential", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Security-Token")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Security-Token", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Algorithm")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Algorithm", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-SignedHeaders", valid_591251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591252: Call_DescribeDatastore_591240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_591252.validator(path, query, header, formData, body)
  let scheme = call_591252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591252.url(scheme.get, call_591252.host, call_591252.base,
                         call_591252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591252, url, valid)

proc call*(call_591253: Call_DescribeDatastore_591240; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  var path_591254 = newJObject()
  var query_591255 = newJObject()
  add(path_591254, "datastoreName", newJString(datastoreName))
  add(query_591255, "includeStatistics", newJBool(includeStatistics))
  result = call_591253.call(path_591254, query_591255, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_591240(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_591241,
    base: "/", url: url_DescribeDatastore_591242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_591272 = ref object of OpenApiRestCall_590364
proc url_DeleteDatastore_591274(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatastore_591273(path: JsonNode; query: JsonNode;
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
  var valid_591275 = path.getOrDefault("datastoreName")
  valid_591275 = validateParameter(valid_591275, JString, required = true,
                                 default = nil)
  if valid_591275 != nil:
    section.add "datastoreName", valid_591275
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
  var valid_591276 = header.getOrDefault("X-Amz-Signature")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Signature", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Content-Sha256", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Date")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Date", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Credential")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Credential", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Security-Token")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Security-Token", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-Algorithm")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Algorithm", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-SignedHeaders", valid_591282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591283: Call_DeleteDatastore_591272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_591283.validator(path, query, header, formData, body)
  let scheme = call_591283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591283.url(scheme.get, call_591283.host, call_591283.base,
                         call_591283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591283, url, valid)

proc call*(call_591284: Call_DeleteDatastore_591272; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_591285 = newJObject()
  add(path_591285, "datastoreName", newJString(datastoreName))
  result = call_591284.call(path_591285, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_591272(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_591273,
    base: "/", url: url_DeleteDatastore_591274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_591300 = ref object of OpenApiRestCall_590364
proc url_UpdatePipeline_591302(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_591301(path: JsonNode; query: JsonNode;
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
  var valid_591303 = path.getOrDefault("pipelineName")
  valid_591303 = validateParameter(valid_591303, JString, required = true,
                                 default = nil)
  if valid_591303 != nil:
    section.add "pipelineName", valid_591303
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
  var valid_591304 = header.getOrDefault("X-Amz-Signature")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Signature", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Content-Sha256", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Date")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Date", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Credential")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Credential", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Security-Token")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Security-Token", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Algorithm")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Algorithm", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-SignedHeaders", valid_591310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591312: Call_UpdatePipeline_591300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_591312.validator(path, query, header, formData, body)
  let scheme = call_591312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591312.url(scheme.get, call_591312.host, call_591312.base,
                         call_591312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591312, url, valid)

proc call*(call_591313: Call_UpdatePipeline_591300; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_591314 = newJObject()
  var body_591315 = newJObject()
  add(path_591314, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_591315 = body
  result = call_591313.call(path_591314, nil, nil, nil, body_591315)

var updatePipeline* = Call_UpdatePipeline_591300(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_591301,
    base: "/", url: url_UpdatePipeline_591302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_591286 = ref object of OpenApiRestCall_590364
proc url_DescribePipeline_591288(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePipeline_591287(path: JsonNode; query: JsonNode;
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
  var valid_591289 = path.getOrDefault("pipelineName")
  valid_591289 = validateParameter(valid_591289, JString, required = true,
                                 default = nil)
  if valid_591289 != nil:
    section.add "pipelineName", valid_591289
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
  var valid_591290 = header.getOrDefault("X-Amz-Signature")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Signature", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Content-Sha256", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Date")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Date", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Credential")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Credential", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Security-Token")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Security-Token", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Algorithm")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Algorithm", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-SignedHeaders", valid_591296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591297: Call_DescribePipeline_591286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_591297.validator(path, query, header, formData, body)
  let scheme = call_591297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591297.url(scheme.get, call_591297.host, call_591297.base,
                         call_591297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591297, url, valid)

proc call*(call_591298: Call_DescribePipeline_591286; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_591299 = newJObject()
  add(path_591299, "pipelineName", newJString(pipelineName))
  result = call_591298.call(path_591299, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_591286(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_591287,
    base: "/", url: url_DescribePipeline_591288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_591316 = ref object of OpenApiRestCall_590364
proc url_DeletePipeline_591318(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_591317(path: JsonNode; query: JsonNode;
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
  var valid_591319 = path.getOrDefault("pipelineName")
  valid_591319 = validateParameter(valid_591319, JString, required = true,
                                 default = nil)
  if valid_591319 != nil:
    section.add "pipelineName", valid_591319
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
  var valid_591320 = header.getOrDefault("X-Amz-Signature")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Signature", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Content-Sha256", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Date")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Date", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Credential")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Credential", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Security-Token")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Security-Token", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Algorithm")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Algorithm", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-SignedHeaders", valid_591326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591327: Call_DeletePipeline_591316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_591327.validator(path, query, header, formData, body)
  let scheme = call_591327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591327.url(scheme.get, call_591327.host, call_591327.base,
                         call_591327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591327, url, valid)

proc call*(call_591328: Call_DeletePipeline_591316; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_591329 = newJObject()
  add(path_591329, "pipelineName", newJString(pipelineName))
  result = call_591328.call(path_591329, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_591316(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_591317,
    base: "/", url: url_DeletePipeline_591318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_591342 = ref object of OpenApiRestCall_590364
proc url_PutLoggingOptions_591344(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLoggingOptions_591343(path: JsonNode; query: JsonNode;
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
  var valid_591345 = header.getOrDefault("X-Amz-Signature")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Signature", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Content-Sha256", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Date")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Date", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Credential")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Credential", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Security-Token")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Security-Token", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Algorithm")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Algorithm", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-SignedHeaders", valid_591351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591353: Call_PutLoggingOptions_591342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_591353.validator(path, query, header, formData, body)
  let scheme = call_591353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591353.url(scheme.get, call_591353.host, call_591353.base,
                         call_591353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591353, url, valid)

proc call*(call_591354: Call_PutLoggingOptions_591342; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_591355 = newJObject()
  if body != nil:
    body_591355 = body
  result = call_591354.call(nil, nil, nil, nil, body_591355)

var putLoggingOptions* = Call_PutLoggingOptions_591342(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_591343, base: "/",
    url: url_PutLoggingOptions_591344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_591330 = ref object of OpenApiRestCall_590364
proc url_DescribeLoggingOptions_591332(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLoggingOptions_591331(path: JsonNode; query: JsonNode;
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
  var valid_591333 = header.getOrDefault("X-Amz-Signature")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Signature", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Content-Sha256", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Date")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Date", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Credential")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Credential", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Security-Token")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Security-Token", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Algorithm")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Algorithm", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-SignedHeaders", valid_591339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591340: Call_DescribeLoggingOptions_591330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_591340.validator(path, query, header, formData, body)
  let scheme = call_591340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591340.url(scheme.get, call_591340.host, call_591340.base,
                         call_591340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591340, url, valid)

proc call*(call_591341: Call_DescribeLoggingOptions_591330): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_591341.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_591330(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_591331, base: "/",
    url: url_DescribeLoggingOptions_591332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_591356 = ref object of OpenApiRestCall_590364
proc url_ListDatasetContents_591358(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasetContents_591357(path: JsonNode; query: JsonNode;
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
  var valid_591359 = path.getOrDefault("datasetName")
  valid_591359 = validateParameter(valid_591359, JString, required = true,
                                 default = nil)
  if valid_591359 != nil:
    section.add "datasetName", valid_591359
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
  var valid_591360 = query.getOrDefault("nextToken")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "nextToken", valid_591360
  var valid_591361 = query.getOrDefault("scheduledOnOrAfter")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "scheduledOnOrAfter", valid_591361
  var valid_591362 = query.getOrDefault("scheduledBefore")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "scheduledBefore", valid_591362
  var valid_591363 = query.getOrDefault("maxResults")
  valid_591363 = validateParameter(valid_591363, JInt, required = false, default = nil)
  if valid_591363 != nil:
    section.add "maxResults", valid_591363
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
  var valid_591364 = header.getOrDefault("X-Amz-Signature")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Signature", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-Content-Sha256", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Date")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Date", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Credential")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Credential", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Security-Token")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Security-Token", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Algorithm")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Algorithm", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-SignedHeaders", valid_591370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591371: Call_ListDatasetContents_591356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_591371.validator(path, query, header, formData, body)
  let scheme = call_591371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591371.url(scheme.get, call_591371.host, call_591371.base,
                         call_591371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591371, url, valid)

proc call*(call_591372: Call_ListDatasetContents_591356; datasetName: string;
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
  var path_591373 = newJObject()
  var query_591374 = newJObject()
  add(query_591374, "nextToken", newJString(nextToken))
  add(query_591374, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(path_591373, "datasetName", newJString(datasetName))
  add(query_591374, "scheduledBefore", newJString(scheduledBefore))
  add(query_591374, "maxResults", newJInt(maxResults))
  result = call_591372.call(path_591373, query_591374, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_591356(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_591357, base: "/",
    url: url_ListDatasetContents_591358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591389 = ref object of OpenApiRestCall_590364
proc url_TagResource_591391(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591392 = query.getOrDefault("resourceArn")
  valid_591392 = validateParameter(valid_591392, JString, required = true,
                                 default = nil)
  if valid_591392 != nil:
    section.add "resourceArn", valid_591392
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
  var valid_591393 = header.getOrDefault("X-Amz-Signature")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-Signature", valid_591393
  var valid_591394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591394 = validateParameter(valid_591394, JString, required = false,
                                 default = nil)
  if valid_591394 != nil:
    section.add "X-Amz-Content-Sha256", valid_591394
  var valid_591395 = header.getOrDefault("X-Amz-Date")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-Date", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Credential")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Credential", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Security-Token")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Security-Token", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Algorithm")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Algorithm", valid_591398
  var valid_591399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-SignedHeaders", valid_591399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591401: Call_TagResource_591389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_591401.validator(path, query, header, formData, body)
  let scheme = call_591401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591401.url(scheme.get, call_591401.host, call_591401.base,
                         call_591401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591401, url, valid)

proc call*(call_591402: Call_TagResource_591389; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  var query_591403 = newJObject()
  var body_591404 = newJObject()
  if body != nil:
    body_591404 = body
  add(query_591403, "resourceArn", newJString(resourceArn))
  result = call_591402.call(nil, query_591403, nil, nil, body_591404)

var tagResource* = Call_TagResource_591389(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_591390,
                                        base: "/", url: url_TagResource_591391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591375 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591377(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591376(path: JsonNode; query: JsonNode;
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
  var valid_591378 = query.getOrDefault("resourceArn")
  valid_591378 = validateParameter(valid_591378, JString, required = true,
                                 default = nil)
  if valid_591378 != nil:
    section.add "resourceArn", valid_591378
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
  var valid_591379 = header.getOrDefault("X-Amz-Signature")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-Signature", valid_591379
  var valid_591380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = nil)
  if valid_591380 != nil:
    section.add "X-Amz-Content-Sha256", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Date")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Date", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Credential")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Credential", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-Security-Token")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-Security-Token", valid_591383
  var valid_591384 = header.getOrDefault("X-Amz-Algorithm")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Algorithm", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-SignedHeaders", valid_591385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591386: Call_ListTagsForResource_591375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_591386.validator(path, query, header, formData, body)
  let scheme = call_591386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591386.url(scheme.get, call_591386.host, call_591386.base,
                         call_591386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591386, url, valid)

proc call*(call_591387: Call_ListTagsForResource_591375; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_591388 = newJObject()
  add(query_591388, "resourceArn", newJString(resourceArn))
  result = call_591387.call(nil, query_591388, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591375(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_591376, base: "/",
    url: url_ListTagsForResource_591377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_591405 = ref object of OpenApiRestCall_590364
proc url_RunPipelineActivity_591407(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RunPipelineActivity_591406(path: JsonNode; query: JsonNode;
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
  var valid_591408 = header.getOrDefault("X-Amz-Signature")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-Signature", valid_591408
  var valid_591409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591409 = validateParameter(valid_591409, JString, required = false,
                                 default = nil)
  if valid_591409 != nil:
    section.add "X-Amz-Content-Sha256", valid_591409
  var valid_591410 = header.getOrDefault("X-Amz-Date")
  valid_591410 = validateParameter(valid_591410, JString, required = false,
                                 default = nil)
  if valid_591410 != nil:
    section.add "X-Amz-Date", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Credential")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Credential", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-Security-Token")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-Security-Token", valid_591412
  var valid_591413 = header.getOrDefault("X-Amz-Algorithm")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = nil)
  if valid_591413 != nil:
    section.add "X-Amz-Algorithm", valid_591413
  var valid_591414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591414 = validateParameter(valid_591414, JString, required = false,
                                 default = nil)
  if valid_591414 != nil:
    section.add "X-Amz-SignedHeaders", valid_591414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591416: Call_RunPipelineActivity_591405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_591416.validator(path, query, header, formData, body)
  let scheme = call_591416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591416.url(scheme.get, call_591416.host, call_591416.base,
                         call_591416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591416, url, valid)

proc call*(call_591417: Call_RunPipelineActivity_591405; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_591418 = newJObject()
  if body != nil:
    body_591418 = body
  result = call_591417.call(nil, nil, nil, nil, body_591418)

var runPipelineActivity* = Call_RunPipelineActivity_591405(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_591406, base: "/",
    url: url_RunPipelineActivity_591407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_591419 = ref object of OpenApiRestCall_590364
proc url_SampleChannelData_591421(protocol: Scheme; host: string; base: string;
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

proc validate_SampleChannelData_591420(path: JsonNode; query: JsonNode;
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
  var valid_591422 = path.getOrDefault("channelName")
  valid_591422 = validateParameter(valid_591422, JString, required = true,
                                 default = nil)
  if valid_591422 != nil:
    section.add "channelName", valid_591422
  result.add "path", section
  ## parameters in `query` object:
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_591423 = query.getOrDefault("startTime")
  valid_591423 = validateParameter(valid_591423, JString, required = false,
                                 default = nil)
  if valid_591423 != nil:
    section.add "startTime", valid_591423
  var valid_591424 = query.getOrDefault("maxMessages")
  valid_591424 = validateParameter(valid_591424, JInt, required = false, default = nil)
  if valid_591424 != nil:
    section.add "maxMessages", valid_591424
  var valid_591425 = query.getOrDefault("endTime")
  valid_591425 = validateParameter(valid_591425, JString, required = false,
                                 default = nil)
  if valid_591425 != nil:
    section.add "endTime", valid_591425
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
  var valid_591426 = header.getOrDefault("X-Amz-Signature")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-Signature", valid_591426
  var valid_591427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591427 = validateParameter(valid_591427, JString, required = false,
                                 default = nil)
  if valid_591427 != nil:
    section.add "X-Amz-Content-Sha256", valid_591427
  var valid_591428 = header.getOrDefault("X-Amz-Date")
  valid_591428 = validateParameter(valid_591428, JString, required = false,
                                 default = nil)
  if valid_591428 != nil:
    section.add "X-Amz-Date", valid_591428
  var valid_591429 = header.getOrDefault("X-Amz-Credential")
  valid_591429 = validateParameter(valid_591429, JString, required = false,
                                 default = nil)
  if valid_591429 != nil:
    section.add "X-Amz-Credential", valid_591429
  var valid_591430 = header.getOrDefault("X-Amz-Security-Token")
  valid_591430 = validateParameter(valid_591430, JString, required = false,
                                 default = nil)
  if valid_591430 != nil:
    section.add "X-Amz-Security-Token", valid_591430
  var valid_591431 = header.getOrDefault("X-Amz-Algorithm")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Algorithm", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-SignedHeaders", valid_591432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591433: Call_SampleChannelData_591419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_591433.validator(path, query, header, formData, body)
  let scheme = call_591433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591433.url(scheme.get, call_591433.host, call_591433.base,
                         call_591433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591433, url, valid)

proc call*(call_591434: Call_SampleChannelData_591419; channelName: string;
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
  var path_591435 = newJObject()
  var query_591436 = newJObject()
  add(query_591436, "startTime", newJString(startTime))
  add(query_591436, "maxMessages", newJInt(maxMessages))
  add(path_591435, "channelName", newJString(channelName))
  add(query_591436, "endTime", newJString(endTime))
  result = call_591434.call(path_591435, query_591436, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_591419(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_591420, base: "/",
    url: url_SampleChannelData_591421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_591437 = ref object of OpenApiRestCall_590364
proc url_StartPipelineReprocessing_591439(protocol: Scheme; host: string;
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

proc validate_StartPipelineReprocessing_591438(path: JsonNode; query: JsonNode;
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
  var valid_591440 = path.getOrDefault("pipelineName")
  valid_591440 = validateParameter(valid_591440, JString, required = true,
                                 default = nil)
  if valid_591440 != nil:
    section.add "pipelineName", valid_591440
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
  var valid_591441 = header.getOrDefault("X-Amz-Signature")
  valid_591441 = validateParameter(valid_591441, JString, required = false,
                                 default = nil)
  if valid_591441 != nil:
    section.add "X-Amz-Signature", valid_591441
  var valid_591442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591442 = validateParameter(valid_591442, JString, required = false,
                                 default = nil)
  if valid_591442 != nil:
    section.add "X-Amz-Content-Sha256", valid_591442
  var valid_591443 = header.getOrDefault("X-Amz-Date")
  valid_591443 = validateParameter(valid_591443, JString, required = false,
                                 default = nil)
  if valid_591443 != nil:
    section.add "X-Amz-Date", valid_591443
  var valid_591444 = header.getOrDefault("X-Amz-Credential")
  valid_591444 = validateParameter(valid_591444, JString, required = false,
                                 default = nil)
  if valid_591444 != nil:
    section.add "X-Amz-Credential", valid_591444
  var valid_591445 = header.getOrDefault("X-Amz-Security-Token")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-Security-Token", valid_591445
  var valid_591446 = header.getOrDefault("X-Amz-Algorithm")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Algorithm", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-SignedHeaders", valid_591447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591449: Call_StartPipelineReprocessing_591437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_591449.validator(path, query, header, formData, body)
  let scheme = call_591449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591449.url(scheme.get, call_591449.host, call_591449.base,
                         call_591449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591449, url, valid)

proc call*(call_591450: Call_StartPipelineReprocessing_591437;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_591451 = newJObject()
  var body_591452 = newJObject()
  add(path_591451, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_591452 = body
  result = call_591450.call(path_591451, nil, nil, nil, body_591452)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_591437(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_591438, base: "/",
    url: url_StartPipelineReprocessing_591439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591453 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591455(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591456 = query.getOrDefault("tagKeys")
  valid_591456 = validateParameter(valid_591456, JArray, required = true, default = nil)
  if valid_591456 != nil:
    section.add "tagKeys", valid_591456
  var valid_591457 = query.getOrDefault("resourceArn")
  valid_591457 = validateParameter(valid_591457, JString, required = true,
                                 default = nil)
  if valid_591457 != nil:
    section.add "resourceArn", valid_591457
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
  var valid_591458 = header.getOrDefault("X-Amz-Signature")
  valid_591458 = validateParameter(valid_591458, JString, required = false,
                                 default = nil)
  if valid_591458 != nil:
    section.add "X-Amz-Signature", valid_591458
  var valid_591459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591459 = validateParameter(valid_591459, JString, required = false,
                                 default = nil)
  if valid_591459 != nil:
    section.add "X-Amz-Content-Sha256", valid_591459
  var valid_591460 = header.getOrDefault("X-Amz-Date")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Date", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Credential")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Credential", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-Security-Token")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-Security-Token", valid_591462
  var valid_591463 = header.getOrDefault("X-Amz-Algorithm")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amz-Algorithm", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-SignedHeaders", valid_591464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591465: Call_UntagResource_591453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_591465.validator(path, query, header, formData, body)
  let scheme = call_591465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591465.url(scheme.get, call_591465.host, call_591465.base,
                         call_591465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591465, url, valid)

proc call*(call_591466: Call_UntagResource_591453; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  var query_591467 = newJObject()
  if tagKeys != nil:
    query_591467.add "tagKeys", tagKeys
  add(query_591467, "resourceArn", newJString(resourceArn))
  result = call_591466.call(nil, query_591467, nil, nil, nil)

var untagResource* = Call_UntagResource_591453(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_591454,
    base: "/", url: url_UntagResource_591455, schemes: {Scheme.Https, Scheme.Http})
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
