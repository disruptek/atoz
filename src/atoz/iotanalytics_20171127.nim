
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchPutMessage_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchPutMessage_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchPutMessage_21625780(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625914: Call_BatchPutMessage_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_BatchPutMessage_21625779; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_21625978 = newJObject()
  if body != nil:
    body_21625978 = body
  result = call_21625977.call(nil, nil, nil, nil, body_21625978)

var batchPutMessage* = Call_BatchPutMessage_21625779(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_21625780,
    base: "/", makeUrl: url_BatchPutMessage_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_21626014 = ref object of OpenApiRestCall_21625435
proc url_CancelPipelineReprocessing_21626016(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelPipelineReprocessing_21626015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626030 = path.getOrDefault("reprocessingId")
  valid_21626030 = validateParameter(valid_21626030, JString, required = true,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "reprocessingId", valid_21626030
  var valid_21626031 = path.getOrDefault("pipelineName")
  valid_21626031 = validateParameter(valid_21626031, JString, required = true,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "pipelineName", valid_21626031
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Algorithm", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Signature")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Signature", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Credential")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Credential", valid_21626038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626039: Call_CancelPipelineReprocessing_21626014;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_21626039.validator(path, query, header, formData, body, _)
  let scheme = call_21626039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626039.makeUrl(scheme.get, call_21626039.host, call_21626039.base,
                               call_21626039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626039, uri, valid, _)

proc call*(call_21626040: Call_CancelPipelineReprocessing_21626014;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_21626042 = newJObject()
  add(path_21626042, "reprocessingId", newJString(reprocessingId))
  add(path_21626042, "pipelineName", newJString(pipelineName))
  result = call_21626040.call(path_21626042, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_21626014(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_21626015, base: "/",
    makeUrl: url_CancelPipelineReprocessing_21626016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_21626061 = ref object of OpenApiRestCall_21625435
proc url_CreateChannel_21626063(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_21626062(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Algorithm", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Signature")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Signature", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Credential")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Credential", valid_21626070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626072: Call_CreateChannel_21626061; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_21626072.validator(path, query, header, formData, body, _)
  let scheme = call_21626072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626072.makeUrl(scheme.get, call_21626072.host, call_21626072.base,
                               call_21626072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626072, uri, valid, _)

proc call*(call_21626073: Call_CreateChannel_21626061; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_21626074 = newJObject()
  if body != nil:
    body_21626074 = body
  result = call_21626073.call(nil, nil, nil, nil, body_21626074)

var createChannel* = Call_CreateChannel_21626061(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_21626062, base: "/",
    makeUrl: url_CreateChannel_21626063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_21626045 = ref object of OpenApiRestCall_21625435
proc url_ListChannels_21626047(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_21626046(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626048 = query.getOrDefault("maxResults")
  valid_21626048 = validateParameter(valid_21626048, JInt, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "maxResults", valid_21626048
  var valid_21626049 = query.getOrDefault("nextToken")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "nextToken", valid_21626049
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626057: Call_ListChannels_21626045; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_21626057.validator(path, query, header, formData, body, _)
  let scheme = call_21626057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626057.makeUrl(scheme.get, call_21626057.host, call_21626057.base,
                               call_21626057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626057, uri, valid, _)

proc call*(call_21626058: Call_ListChannels_21626045; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_21626059 = newJObject()
  add(query_21626059, "maxResults", newJInt(maxResults))
  add(query_21626059, "nextToken", newJString(nextToken))
  result = call_21626058.call(nil, query_21626059, nil, nil, nil)

var listChannels* = Call_ListChannels_21626045(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_21626046, base: "/",
    makeUrl: url_ListChannels_21626047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_21626090 = ref object of OpenApiRestCall_21625435
proc url_CreateDataset_21626092(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataset_21626091(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626093 = header.getOrDefault("X-Amz-Date")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Date", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Security-Token", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_CreateDataset_21626090; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_CreateDataset_21626090; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var createDataset* = Call_CreateDataset_21626090(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_21626091, base: "/",
    makeUrl: url_CreateDataset_21626092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_21626075 = ref object of OpenApiRestCall_21625435
proc url_ListDatasets_21626077(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasets_21626076(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626078 = query.getOrDefault("maxResults")
  valid_21626078 = validateParameter(valid_21626078, JInt, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "maxResults", valid_21626078
  var valid_21626079 = query.getOrDefault("nextToken")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "nextToken", valid_21626079
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
  var valid_21626080 = header.getOrDefault("X-Amz-Date")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Date", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Security-Token", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626087: Call_ListDatasets_21626075; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_21626087.validator(path, query, header, formData, body, _)
  let scheme = call_21626087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626087.makeUrl(scheme.get, call_21626087.host, call_21626087.base,
                               call_21626087.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626087, uri, valid, _)

proc call*(call_21626088: Call_ListDatasets_21626075; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_21626089 = newJObject()
  add(query_21626089, "maxResults", newJInt(maxResults))
  add(query_21626089, "nextToken", newJString(nextToken))
  result = call_21626088.call(nil, query_21626089, nil, nil, nil)

var listDatasets* = Call_ListDatasets_21626075(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_21626076, base: "/",
    makeUrl: url_ListDatasets_21626077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_21626120 = ref object of OpenApiRestCall_21625435
proc url_CreateDatasetContent_21626122(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDatasetContent_21626121(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626123 = path.getOrDefault("datasetName")
  valid_21626123 = validateParameter(valid_21626123, JString, required = true,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "datasetName", valid_21626123
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
  var valid_21626124 = header.getOrDefault("X-Amz-Date")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Date", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Security-Token", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Algorithm", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Signature")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Signature", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Credential")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Credential", valid_21626130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_CreateDatasetContent_21626120; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateDatasetContent_21626120; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_21626133 = newJObject()
  add(path_21626133, "datasetName", newJString(datasetName))
  result = call_21626132.call(path_21626133, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_21626120(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_21626121, base: "/",
    makeUrl: url_CreateDatasetContent_21626122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_21626104 = ref object of OpenApiRestCall_21625435
proc url_GetDatasetContent_21626106(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDatasetContent_21626105(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626107 = path.getOrDefault("datasetName")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "datasetName", valid_21626107
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_21626108 = query.getOrDefault("versionId")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "versionId", valid_21626108
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
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Algorithm", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Signature")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Signature", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Credential")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Credential", valid_21626115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_GetDatasetContent_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_GetDatasetContent_21626104; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_21626118 = newJObject()
  var query_21626119 = newJObject()
  add(query_21626119, "versionId", newJString(versionId))
  add(path_21626118, "datasetName", newJString(datasetName))
  result = call_21626117.call(path_21626118, query_21626119, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_21626104(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_21626105, base: "/",
    makeUrl: url_GetDatasetContent_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_21626134 = ref object of OpenApiRestCall_21625435
proc url_DeleteDatasetContent_21626136(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDatasetContent_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = path.getOrDefault("datasetName")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "datasetName", valid_21626137
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_21626138 = query.getOrDefault("versionId")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "versionId", valid_21626138
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
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Algorithm", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Signature")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Signature", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Credential")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Credential", valid_21626145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_DeleteDatasetContent_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_DeleteDatasetContent_21626134; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_21626148 = newJObject()
  var query_21626149 = newJObject()
  add(query_21626149, "versionId", newJString(versionId))
  add(path_21626148, "datasetName", newJString(datasetName))
  result = call_21626147.call(path_21626148, query_21626149, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_21626134(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_21626135, base: "/",
    makeUrl: url_DeleteDatasetContent_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_21626165 = ref object of OpenApiRestCall_21625435
proc url_CreateDatastore_21626167(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatastore_21626166(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626168 = header.getOrDefault("X-Amz-Date")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Date", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Security-Token", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_CreateDatastore_21626165; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreateDatastore_21626165; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createDatastore* = Call_CreateDatastore_21626165(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_21626166, base: "/",
    makeUrl: url_CreateDatastore_21626167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_21626150 = ref object of OpenApiRestCall_21625435
proc url_ListDatastores_21626152(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatastores_21626151(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626153 = query.getOrDefault("maxResults")
  valid_21626153 = validateParameter(valid_21626153, JInt, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "maxResults", valid_21626153
  var valid_21626154 = query.getOrDefault("nextToken")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "nextToken", valid_21626154
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
  var valid_21626155 = header.getOrDefault("X-Amz-Date")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Date", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Security-Token", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626162: Call_ListDatastores_21626150; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_21626162.validator(path, query, header, formData, body, _)
  let scheme = call_21626162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626162.makeUrl(scheme.get, call_21626162.host, call_21626162.base,
                               call_21626162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626162, uri, valid, _)

proc call*(call_21626163: Call_ListDatastores_21626150; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_21626164 = newJObject()
  add(query_21626164, "maxResults", newJInt(maxResults))
  add(query_21626164, "nextToken", newJString(nextToken))
  result = call_21626163.call(nil, query_21626164, nil, nil, nil)

var listDatastores* = Call_ListDatastores_21626150(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_21626151, base: "/",
    makeUrl: url_ListDatastores_21626152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreatePipeline_21626196(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_21626195(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Signature")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Signature", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Credential")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Credential", valid_21626203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_CreatePipeline_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_CreatePipeline_21626194; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_21626207 = newJObject()
  if body != nil:
    body_21626207 = body
  result = call_21626206.call(nil, nil, nil, nil, body_21626207)

var createPipeline* = Call_CreatePipeline_21626194(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_21626195, base: "/",
    makeUrl: url_CreatePipeline_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_21626179 = ref object of OpenApiRestCall_21625435
proc url_ListPipelines_21626181(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_21626180(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626182 = query.getOrDefault("maxResults")
  valid_21626182 = validateParameter(valid_21626182, JInt, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "maxResults", valid_21626182
  var valid_21626183 = query.getOrDefault("nextToken")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "nextToken", valid_21626183
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
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Algorithm", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Signature")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Signature", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Credential")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Credential", valid_21626190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_ListPipelines_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_ListPipelines_21626179; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_21626193 = newJObject()
  add(query_21626193, "maxResults", newJInt(maxResults))
  add(query_21626193, "nextToken", newJString(nextToken))
  result = call_21626192.call(nil, query_21626193, nil, nil, nil)

var listPipelines* = Call_ListPipelines_21626179(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_21626180, base: "/",
    makeUrl: url_ListPipelines_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_21626224 = ref object of OpenApiRestCall_21625435
proc url_UpdateChannel_21626226(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_21626225(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626227 = path.getOrDefault("channelName")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "channelName", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_UpdateChannel_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_UpdateChannel_21626224; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_21626238 = newJObject()
  var body_21626239 = newJObject()
  add(path_21626238, "channelName", newJString(channelName))
  if body != nil:
    body_21626239 = body
  result = call_21626237.call(path_21626238, nil, nil, nil, body_21626239)

var updateChannel* = Call_UpdateChannel_21626224(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_21626225,
    base: "/", makeUrl: url_UpdateChannel_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_21626208 = ref object of OpenApiRestCall_21625435
proc url_DescribeChannel_21626210(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_21626209(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626211 = path.getOrDefault("channelName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "channelName", valid_21626211
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_21626212 = query.getOrDefault("includeStatistics")
  valid_21626212 = validateParameter(valid_21626212, JBool, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "includeStatistics", valid_21626212
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
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626220: Call_DescribeChannel_21626208; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_DescribeChannel_21626208; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  var path_21626222 = newJObject()
  var query_21626223 = newJObject()
  add(path_21626222, "channelName", newJString(channelName))
  add(query_21626223, "includeStatistics", newJBool(includeStatistics))
  result = call_21626221.call(path_21626222, query_21626223, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_21626208(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_21626209,
    base: "/", makeUrl: url_DescribeChannel_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_21626240 = ref object of OpenApiRestCall_21625435
proc url_DeleteChannel_21626242(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_21626241(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626243 = path.getOrDefault("channelName")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "channelName", valid_21626243
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
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Algorithm", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Signature")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Signature", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Credential")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Credential", valid_21626250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_DeleteChannel_21626240; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DeleteChannel_21626240; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_21626253 = newJObject()
  add(path_21626253, "channelName", newJString(channelName))
  result = call_21626252.call(path_21626253, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_21626240(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_21626241,
    base: "/", makeUrl: url_DeleteChannel_21626242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_21626268 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataset_21626270(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataset_21626269(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626271 = path.getOrDefault("datasetName")
  valid_21626271 = validateParameter(valid_21626271, JString, required = true,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "datasetName", valid_21626271
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Algorithm", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Signature")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Signature", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Credential")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Credential", valid_21626278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626280: Call_UpdateDataset_21626268; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_21626280.validator(path, query, header, formData, body, _)
  let scheme = call_21626280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626280.makeUrl(scheme.get, call_21626280.host, call_21626280.base,
                               call_21626280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626280, uri, valid, _)

proc call*(call_21626281: Call_UpdateDataset_21626268; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_21626282 = newJObject()
  var body_21626283 = newJObject()
  add(path_21626282, "datasetName", newJString(datasetName))
  if body != nil:
    body_21626283 = body
  result = call_21626281.call(path_21626282, nil, nil, nil, body_21626283)

var updateDataset* = Call_UpdateDataset_21626268(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_21626269,
    base: "/", makeUrl: url_UpdateDataset_21626270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_21626254 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataset_21626256(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataset_21626255(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626257 = path.getOrDefault("datasetName")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "datasetName", valid_21626257
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
  var valid_21626258 = header.getOrDefault("X-Amz-Date")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Date", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Security-Token", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626265: Call_DescribeDataset_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_21626265.validator(path, query, header, formData, body, _)
  let scheme = call_21626265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626265.makeUrl(scheme.get, call_21626265.host, call_21626265.base,
                               call_21626265.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626265, uri, valid, _)

proc call*(call_21626266: Call_DescribeDataset_21626254; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_21626267 = newJObject()
  add(path_21626267, "datasetName", newJString(datasetName))
  result = call_21626266.call(path_21626267, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_21626254(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_21626255,
    base: "/", makeUrl: url_DescribeDataset_21626256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_21626284 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataset_21626286(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataset_21626285(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626287 = path.getOrDefault("datasetName")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "datasetName", valid_21626287
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
  var valid_21626288 = header.getOrDefault("X-Amz-Date")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Date", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Security-Token", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626295: Call_DeleteDataset_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_21626295.validator(path, query, header, formData, body, _)
  let scheme = call_21626295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626295.makeUrl(scheme.get, call_21626295.host, call_21626295.base,
                               call_21626295.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626295, uri, valid, _)

proc call*(call_21626296: Call_DeleteDataset_21626284; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_21626297 = newJObject()
  add(path_21626297, "datasetName", newJString(datasetName))
  result = call_21626296.call(path_21626297, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_21626284(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_21626285,
    base: "/", makeUrl: url_DeleteDataset_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_21626314 = ref object of OpenApiRestCall_21625435
proc url_UpdateDatastore_21626316(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDatastore_21626315(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626317 = path.getOrDefault("datastoreName")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "datastoreName", valid_21626317
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
  var valid_21626318 = header.getOrDefault("X-Amz-Date")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Date", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Security-Token", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_UpdateDatastore_21626314; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_UpdateDatastore_21626314; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_21626328 = newJObject()
  var body_21626329 = newJObject()
  add(path_21626328, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_21626329 = body
  result = call_21626327.call(path_21626328, nil, nil, nil, body_21626329)

var updateDatastore* = Call_UpdateDatastore_21626314(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_21626315,
    base: "/", makeUrl: url_UpdateDatastore_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_21626298 = ref object of OpenApiRestCall_21625435
proc url_DescribeDatastore_21626300(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDatastore_21626299(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626301 = path.getOrDefault("datastoreName")
  valid_21626301 = validateParameter(valid_21626301, JString, required = true,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "datastoreName", valid_21626301
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_21626302 = query.getOrDefault("includeStatistics")
  valid_21626302 = validateParameter(valid_21626302, JBool, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "includeStatistics", valid_21626302
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
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626310: Call_DescribeDatastore_21626298; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_21626310.validator(path, query, header, formData, body, _)
  let scheme = call_21626310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626310.makeUrl(scheme.get, call_21626310.host, call_21626310.base,
                               call_21626310.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626310, uri, valid, _)

proc call*(call_21626311: Call_DescribeDatastore_21626298; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  var path_21626312 = newJObject()
  var query_21626313 = newJObject()
  add(query_21626313, "includeStatistics", newJBool(includeStatistics))
  add(path_21626312, "datastoreName", newJString(datastoreName))
  result = call_21626311.call(path_21626312, query_21626313, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_21626298(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_21626299,
    base: "/", makeUrl: url_DescribeDatastore_21626300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_21626330 = ref object of OpenApiRestCall_21625435
proc url_DeleteDatastore_21626332(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDatastore_21626331(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626333 = path.getOrDefault("datastoreName")
  valid_21626333 = validateParameter(valid_21626333, JString, required = true,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "datastoreName", valid_21626333
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
  var valid_21626334 = header.getOrDefault("X-Amz-Date")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Date", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Security-Token", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Algorithm", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Signature")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Signature", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Credential")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Credential", valid_21626340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_DeleteDatastore_21626330; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DeleteDatastore_21626330; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_21626343 = newJObject()
  add(path_21626343, "datastoreName", newJString(datastoreName))
  result = call_21626342.call(path_21626343, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_21626330(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_21626331,
    base: "/", makeUrl: url_DeleteDatastore_21626332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_21626358 = ref object of OpenApiRestCall_21625435
proc url_UpdatePipeline_21626360(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipeline_21626359(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626361 = path.getOrDefault("pipelineName")
  valid_21626361 = validateParameter(valid_21626361, JString, required = true,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "pipelineName", valid_21626361
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Algorithm", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Signature")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Signature", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Credential")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Credential", valid_21626368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626370: Call_UpdatePipeline_21626358; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_21626370.validator(path, query, header, formData, body, _)
  let scheme = call_21626370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626370.makeUrl(scheme.get, call_21626370.host, call_21626370.base,
                               call_21626370.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626370, uri, valid, _)

proc call*(call_21626371: Call_UpdatePipeline_21626358; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_21626372 = newJObject()
  var body_21626373 = newJObject()
  add(path_21626372, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_21626373 = body
  result = call_21626371.call(path_21626372, nil, nil, nil, body_21626373)

var updatePipeline* = Call_UpdatePipeline_21626358(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_21626359,
    base: "/", makeUrl: url_UpdatePipeline_21626360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_21626344 = ref object of OpenApiRestCall_21625435
proc url_DescribePipeline_21626346(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePipeline_21626345(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626347 = path.getOrDefault("pipelineName")
  valid_21626347 = validateParameter(valid_21626347, JString, required = true,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "pipelineName", valid_21626347
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
  var valid_21626348 = header.getOrDefault("X-Amz-Date")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Date", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Security-Token", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626355: Call_DescribePipeline_21626344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_21626355.validator(path, query, header, formData, body, _)
  let scheme = call_21626355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626355.makeUrl(scheme.get, call_21626355.host, call_21626355.base,
                               call_21626355.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626355, uri, valid, _)

proc call*(call_21626356: Call_DescribePipeline_21626344; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_21626357 = newJObject()
  add(path_21626357, "pipelineName", newJString(pipelineName))
  result = call_21626356.call(path_21626357, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_21626344(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_21626345,
    base: "/", makeUrl: url_DescribePipeline_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_21626374 = ref object of OpenApiRestCall_21625435
proc url_DeletePipeline_21626376(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePipeline_21626375(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626377 = path.getOrDefault("pipelineName")
  valid_21626377 = validateParameter(valid_21626377, JString, required = true,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "pipelineName", valid_21626377
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
  var valid_21626378 = header.getOrDefault("X-Amz-Date")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Date", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Security-Token", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626385: Call_DeletePipeline_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_21626385.validator(path, query, header, formData, body, _)
  let scheme = call_21626385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626385.makeUrl(scheme.get, call_21626385.host, call_21626385.base,
                               call_21626385.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626385, uri, valid, _)

proc call*(call_21626386: Call_DeletePipeline_21626374; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_21626387 = newJObject()
  add(path_21626387, "pipelineName", newJString(pipelineName))
  result = call_21626386.call(path_21626387, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_21626374(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_21626375,
    base: "/", makeUrl: url_DeletePipeline_21626376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_21626400 = ref object of OpenApiRestCall_21625435
proc url_PutLoggingOptions_21626402(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_21626401(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626403 = header.getOrDefault("X-Amz-Date")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Date", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Security-Token", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Algorithm", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Signature")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Signature", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Credential")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Credential", valid_21626409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626411: Call_PutLoggingOptions_21626400; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_21626411.validator(path, query, header, formData, body, _)
  let scheme = call_21626411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626411.makeUrl(scheme.get, call_21626411.host, call_21626411.base,
                               call_21626411.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626411, uri, valid, _)

proc call*(call_21626412: Call_PutLoggingOptions_21626400; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_21626413 = newJObject()
  if body != nil:
    body_21626413 = body
  result = call_21626412.call(nil, nil, nil, nil, body_21626413)

var putLoggingOptions* = Call_PutLoggingOptions_21626400(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_21626401, base: "/",
    makeUrl: url_PutLoggingOptions_21626402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_21626388 = ref object of OpenApiRestCall_21625435
proc url_DescribeLoggingOptions_21626390(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_21626389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_DescribeLoggingOptions_21626388;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_DescribeLoggingOptions_21626388): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_21626399.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_21626388(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_21626389, base: "/",
    makeUrl: url_DescribeLoggingOptions_21626390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_21626414 = ref object of OpenApiRestCall_21625435
proc url_ListDatasetContents_21626416(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDatasetContents_21626415(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626417 = path.getOrDefault("datasetName")
  valid_21626417 = validateParameter(valid_21626417, JString, required = true,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "datasetName", valid_21626417
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
  var valid_21626418 = query.getOrDefault("scheduledOnOrAfter")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "scheduledOnOrAfter", valid_21626418
  var valid_21626419 = query.getOrDefault("scheduledBefore")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "scheduledBefore", valid_21626419
  var valid_21626420 = query.getOrDefault("maxResults")
  valid_21626420 = validateParameter(valid_21626420, JInt, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "maxResults", valid_21626420
  var valid_21626421 = query.getOrDefault("nextToken")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "nextToken", valid_21626421
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
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Algorithm", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Signature")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Signature", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Credential")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Credential", valid_21626428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626429: Call_ListDatasetContents_21626414; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_21626429.validator(path, query, header, formData, body, _)
  let scheme = call_21626429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626429.makeUrl(scheme.get, call_21626429.host, call_21626429.base,
                               call_21626429.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626429, uri, valid, _)

proc call*(call_21626430: Call_ListDatasetContents_21626414; datasetName: string;
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
  var path_21626431 = newJObject()
  var query_21626432 = newJObject()
  add(query_21626432, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(query_21626432, "scheduledBefore", newJString(scheduledBefore))
  add(query_21626432, "maxResults", newJInt(maxResults))
  add(query_21626432, "nextToken", newJString(nextToken))
  add(path_21626431, "datasetName", newJString(datasetName))
  result = call_21626430.call(path_21626431, query_21626432, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_21626414(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_21626415, base: "/",
    makeUrl: url_ListDatasetContents_21626416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626447 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626449(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626448(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626450 = query.getOrDefault("resourceArn")
  valid_21626450 = validateParameter(valid_21626450, JString, required = true,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "resourceArn", valid_21626450
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
  var valid_21626451 = header.getOrDefault("X-Amz-Date")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Date", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Security-Token", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Algorithm", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Signature")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Signature", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Credential")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Credential", valid_21626457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626459: Call_TagResource_21626447; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_21626459.validator(path, query, header, formData, body, _)
  let scheme = call_21626459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626459.makeUrl(scheme.get, call_21626459.host, call_21626459.base,
                               call_21626459.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626459, uri, valid, _)

proc call*(call_21626460: Call_TagResource_21626447; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  ##   body: JObject (required)
  var query_21626461 = newJObject()
  var body_21626462 = newJObject()
  add(query_21626461, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_21626462 = body
  result = call_21626460.call(nil, query_21626461, nil, nil, body_21626462)

var tagResource* = Call_TagResource_21626447(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn", validator: validate_TagResource_21626448, base: "/",
    makeUrl: url_TagResource_21626449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626433 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626435(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626436 = query.getOrDefault("resourceArn")
  valid_21626436 = validateParameter(valid_21626436, JString, required = true,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "resourceArn", valid_21626436
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Algorithm", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Signature")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Signature", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Credential")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Credential", valid_21626443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626444: Call_ListTagsForResource_21626433; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_21626444.validator(path, query, header, formData, body, _)
  let scheme = call_21626444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626444.makeUrl(scheme.get, call_21626444.host, call_21626444.base,
                               call_21626444.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626444, uri, valid, _)

proc call*(call_21626445: Call_ListTagsForResource_21626433; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_21626446 = newJObject()
  add(query_21626446, "resourceArn", newJString(resourceArn))
  result = call_21626445.call(nil, query_21626446, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626433(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_21626434, base: "/",
    makeUrl: url_ListTagsForResource_21626435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_21626463 = ref object of OpenApiRestCall_21625435
proc url_RunPipelineActivity_21626465(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RunPipelineActivity_21626464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626466 = header.getOrDefault("X-Amz-Date")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Date", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Security-Token", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Algorithm", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Signature")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Signature", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Credential")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Credential", valid_21626472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626474: Call_RunPipelineActivity_21626463; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_21626474.validator(path, query, header, formData, body, _)
  let scheme = call_21626474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626474.makeUrl(scheme.get, call_21626474.host, call_21626474.base,
                               call_21626474.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626474, uri, valid, _)

proc call*(call_21626475: Call_RunPipelineActivity_21626463; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_21626476 = newJObject()
  if body != nil:
    body_21626476 = body
  result = call_21626475.call(nil, nil, nil, nil, body_21626476)

var runPipelineActivity* = Call_RunPipelineActivity_21626463(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_21626464, base: "/",
    makeUrl: url_RunPipelineActivity_21626465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_21626477 = ref object of OpenApiRestCall_21625435
proc url_SampleChannelData_21626479(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SampleChannelData_21626478(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626480 = path.getOrDefault("channelName")
  valid_21626480 = validateParameter(valid_21626480, JString, required = true,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "channelName", valid_21626480
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_21626481 = query.getOrDefault("endTime")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "endTime", valid_21626481
  var valid_21626482 = query.getOrDefault("maxMessages")
  valid_21626482 = validateParameter(valid_21626482, JInt, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "maxMessages", valid_21626482
  var valid_21626483 = query.getOrDefault("startTime")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "startTime", valid_21626483
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
  var valid_21626484 = header.getOrDefault("X-Amz-Date")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Date", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Security-Token", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Algorithm", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Signature")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Signature", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Credential")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Credential", valid_21626490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626491: Call_SampleChannelData_21626477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_SampleChannelData_21626477; channelName: string;
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
  var path_21626493 = newJObject()
  var query_21626494 = newJObject()
  add(query_21626494, "endTime", newJString(endTime))
  add(query_21626494, "maxMessages", newJInt(maxMessages))
  add(path_21626493, "channelName", newJString(channelName))
  add(query_21626494, "startTime", newJString(startTime))
  result = call_21626492.call(path_21626493, query_21626494, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_21626477(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_21626478, base: "/",
    makeUrl: url_SampleChannelData_21626479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_21626495 = ref object of OpenApiRestCall_21625435
proc url_StartPipelineReprocessing_21626497(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartPipelineReprocessing_21626496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626498 = path.getOrDefault("pipelineName")
  valid_21626498 = validateParameter(valid_21626498, JString, required = true,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "pipelineName", valid_21626498
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
  var valid_21626499 = header.getOrDefault("X-Amz-Date")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Date", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Security-Token", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Algorithm", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Signature")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Signature", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Credential")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Credential", valid_21626505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626507: Call_StartPipelineReprocessing_21626495;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_21626507.validator(path, query, header, formData, body, _)
  let scheme = call_21626507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626507.makeUrl(scheme.get, call_21626507.host, call_21626507.base,
                               call_21626507.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626507, uri, valid, _)

proc call*(call_21626508: Call_StartPipelineReprocessing_21626495;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_21626509 = newJObject()
  var body_21626510 = newJObject()
  add(path_21626509, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_21626510 = body
  result = call_21626508.call(path_21626509, nil, nil, nil, body_21626510)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_21626495(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_21626496, base: "/",
    makeUrl: url_StartPipelineReprocessing_21626497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626511 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626513(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626512(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626514 = query.getOrDefault("resourceArn")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "resourceArn", valid_21626514
  var valid_21626515 = query.getOrDefault("tagKeys")
  valid_21626515 = validateParameter(valid_21626515, JArray, required = true,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "tagKeys", valid_21626515
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
  var valid_21626516 = header.getOrDefault("X-Amz-Date")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Date", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Security-Token", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Algorithm", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Signature")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Signature", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Credential")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Credential", valid_21626522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626523: Call_UntagResource_21626511; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_21626523.validator(path, query, header, formData, body, _)
  let scheme = call_21626523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626523.makeUrl(scheme.get, call_21626523.host, call_21626523.base,
                               call_21626523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626523, uri, valid, _)

proc call*(call_21626524: Call_UntagResource_21626511; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var query_21626525 = newJObject()
  add(query_21626525, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_21626525.add "tagKeys", tagKeys
  result = call_21626524.call(nil, query_21626525, nil, nil, nil)

var untagResource* = Call_UntagResource_21626511(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_21626512,
    base: "/", makeUrl: url_UntagResource_21626513,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}