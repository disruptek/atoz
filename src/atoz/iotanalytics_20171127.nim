
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "iotanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotanalytics.ap-southeast-1.amazonaws.com", "us-west-2": "iotanalytics.us-west-2.amazonaws.com", "eu-west-2": "iotanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "iotanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "iotanalytics.eu-central-1.amazonaws.com", "us-east-2": "iotanalytics.us-east-2.amazonaws.com", "us-east-1": "iotanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "iotanalytics.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "iotanalytics.ap-south-1.amazonaws.com", "eu-north-1": "iotanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "iotanalytics.ap-northeast-2.amazonaws.com", "us-west-1": "iotanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "iotanalytics.us-gov-east-1.amazonaws.com", "eu-west-3": "iotanalytics.eu-west-3.amazonaws.com", "cn-north-1": "iotanalytics.cn-north-1.amazonaws.com.cn", "sa-east-1": "iotanalytics.sa-east-1.amazonaws.com", "eu-west-1": "iotanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "iotanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "iotanalytics.ap-southeast-2.amazonaws.com", "ca-central-1": "iotanalytics.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchPutMessage_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchPutMessage_402656296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchPutMessage_402656295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Security-Token", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Signature")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Signature", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Algorithm", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Date")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Date", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Credential")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Credential", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656384
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

proc call*(call_402656399: Call_BatchPutMessage_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends messages to a channel.
                                                                                         ## 
  let valid = call_402656399.validator(path, query, header, formData, body, _)
  let scheme = call_402656399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656399.makeUrl(scheme.get, call_402656399.host, call_402656399.base,
                                   call_402656399.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656399, uri, valid, _)

proc call*(call_402656448: Call_BatchPutMessage_402656294; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_402656449 = newJObject()
  if body != nil:
    body_402656449 = body
  result = call_402656448.call(nil, nil, nil, nil, body_402656449)

var batchPutMessage* = Call_BatchPutMessage_402656294(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_402656295,
    base: "/", makeUrl: url_BatchPutMessage_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_402656476 = ref object of OpenApiRestCall_402656044
proc url_CancelPipelineReprocessing_402656478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "pipelineName" in path, "`pipelineName` is a required path parameter"
  assert "reprocessingId" in path,
         "`reprocessingId` is a required path parameter"
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

proc validate_CancelPipelineReprocessing_402656477(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Cancels the reprocessing of data through the pipeline.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   pipelineName: JString (required)
                                 ##               : The name of pipeline for which data reprocessing is canceled.
  ##   
                                                                                                                 ## reprocessingId: JString (required)
                                                                                                                 ##                 
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## ID 
                                                                                                                 ## of 
                                                                                                                 ## the 
                                                                                                                 ## reprocessing 
                                                                                                                 ## task 
                                                                                                                 ## (returned 
                                                                                                                 ## by 
                                                                                                                 ## "StartPipelineReprocessing").
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `pipelineName` field"
  var valid_402656490 = path.getOrDefault("pipelineName")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "pipelineName", valid_402656490
  var valid_402656491 = path.getOrDefault("reprocessingId")
  valid_402656491 = validateParameter(valid_402656491, JString, required = true,
                                      default = nil)
  if valid_402656491 != nil:
    section.add "reprocessingId", valid_402656491
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Security-Token", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Signature")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Signature", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Algorithm", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Date")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Date", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Credential")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Credential", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656499: Call_CancelPipelineReprocessing_402656476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
                                                                                         ## 
  let valid = call_402656499.validator(path, query, header, formData, body, _)
  let scheme = call_402656499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656499.makeUrl(scheme.get, call_402656499.host, call_402656499.base,
                                   call_402656499.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656499, uri, valid, _)

proc call*(call_402656500: Call_CancelPipelineReprocessing_402656476;
           pipelineName: string; reprocessingId: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   pipelineName: string (required)
                                                           ##               : The name of pipeline for which data reprocessing is canceled.
  ##   
                                                                                                                                           ## reprocessingId: string (required)
                                                                                                                                           ##                 
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## ID 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## reprocessing 
                                                                                                                                           ## task 
                                                                                                                                           ## (returned 
                                                                                                                                           ## by 
                                                                                                                                           ## "StartPipelineReprocessing").
  var path_402656501 = newJObject()
  add(path_402656501, "pipelineName", newJString(pipelineName))
  add(path_402656501, "reprocessingId", newJString(reprocessingId))
  result = call_402656500.call(path_402656501, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_402656476(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_402656477, base: "/",
    makeUrl: url_CancelPipelineReprocessing_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_402656517 = ref object of OpenApiRestCall_402656044
proc url_CreateChannel_402656519(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_402656518(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656520 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Security-Token", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Signature")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Signature", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Algorithm", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Date")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Date", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Credential")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Credential", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656526
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

proc call*(call_402656528: Call_CreateChannel_402656517; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
                                                                                         ## 
  let valid = call_402656528.validator(path, query, header, formData, body, _)
  let scheme = call_402656528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656528.makeUrl(scheme.get, call_402656528.host, call_402656528.base,
                                   call_402656528.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656528, uri, valid, _)

proc call*(call_402656529: Call_CreateChannel_402656517; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   
                                                                                                                                                       ## body: JObject (required)
  var body_402656530 = newJObject()
  if body != nil:
    body_402656530 = body
  result = call_402656529.call(nil, nil, nil, nil, body_402656530)

var createChannel* = Call_CreateChannel_402656517(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_402656518, base: "/",
    makeUrl: url_CreateChannel_402656519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_402656502 = ref object of OpenApiRestCall_402656044
proc url_ListChannels_402656504(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_402656503(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of channels.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                   ## nextToken: JString
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## token 
                                                                                                                                                   ## for 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## set 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  section = newJObject()
  var valid_402656505 = query.getOrDefault("maxResults")
  valid_402656505 = validateParameter(valid_402656505, JInt, required = false,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "maxResults", valid_402656505
  var valid_402656506 = query.getOrDefault("nextToken")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "nextToken", valid_402656506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656514: Call_ListChannels_402656502; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of channels.
                                                                                         ## 
  let valid = call_402656514.validator(path, query, header, formData, body, _)
  let scheme = call_402656514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656514.makeUrl(scheme.get, call_402656514.host, call_402656514.base,
                                   call_402656514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656514, uri, valid, _)

proc call*(call_402656515: Call_ListChannels_402656502; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   maxResults: int
                                  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                   ## nextToken: string
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## token 
                                                                                                                                                   ## for 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## set 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  var query_402656516 = newJObject()
  add(query_402656516, "maxResults", newJInt(maxResults))
  add(query_402656516, "nextToken", newJString(nextToken))
  result = call_402656515.call(nil, query_402656516, nil, nil, nil)

var listChannels* = Call_ListChannels_402656502(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_402656503, base: "/",
    makeUrl: url_ListChannels_402656504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_402656546 = ref object of OpenApiRestCall_402656044
proc url_CreateDataset_402656548(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataset_402656547(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656549 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Security-Token", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Signature")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Signature", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Algorithm", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Date")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Date", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Credential")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Credential", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656555
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

proc call*(call_402656557: Call_CreateDataset_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
                                                                                         ## 
  let valid = call_402656557.validator(path, query, header, formData, body, _)
  let scheme = call_402656557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656557.makeUrl(scheme.get, call_402656557.host, call_402656557.base,
                                   call_402656557.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656557, uri, valid, _)

proc call*(call_402656558: Call_CreateDataset_402656546; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   
                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656559 = newJObject()
  if body != nil:
    body_402656559 = body
  result = call_402656558.call(nil, nil, nil, nil, body_402656559)

var createDataset* = Call_CreateDataset_402656546(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_402656547, base: "/",
    makeUrl: url_CreateDataset_402656548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_402656531 = ref object of OpenApiRestCall_402656044
proc url_ListDatasets_402656533(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasets_402656532(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about data sets.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                   ## nextToken: JString
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## token 
                                                                                                                                                   ## for 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## set 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  section = newJObject()
  var valid_402656534 = query.getOrDefault("maxResults")
  valid_402656534 = validateParameter(valid_402656534, JInt, required = false,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "maxResults", valid_402656534
  var valid_402656535 = query.getOrDefault("nextToken")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "nextToken", valid_402656535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656543: Call_ListDatasets_402656531; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about data sets.
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_ListDatasets_402656531; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   maxResults: int
                                           ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                            ## nextToken: string
                                                                                                                                                            ##            
                                                                                                                                                            ## : 
                                                                                                                                                            ## The 
                                                                                                                                                            ## token 
                                                                                                                                                            ## for 
                                                                                                                                                            ## the 
                                                                                                                                                            ## next 
                                                                                                                                                            ## set 
                                                                                                                                                            ## of 
                                                                                                                                                            ## results.
  var query_402656545 = newJObject()
  add(query_402656545, "maxResults", newJInt(maxResults))
  add(query_402656545, "nextToken", newJString(nextToken))
  result = call_402656544.call(nil, query_402656545, nil, nil, nil)

var listDatasets* = Call_ListDatasets_402656531(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_402656532, base: "/",
    makeUrl: url_ListDatasets_402656533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_402656576 = ref object of OpenApiRestCall_402656044
proc url_CreateDatasetContent_402656578(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateDatasetContent_402656577(path: JsonNode; query: JsonNode;
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
  var valid_402656579 = path.getOrDefault("datasetName")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "datasetName", valid_402656579
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656587: Call_CreateDatasetContent_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
                                                                                         ## 
  let valid = call_402656587.validator(path, query, header, formData, body, _)
  let scheme = call_402656587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656587.makeUrl(scheme.get, call_402656587.host, call_402656587.base,
                                   call_402656587.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656587, uri, valid, _)

proc call*(call_402656588: Call_CreateDatasetContent_402656576;
           datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   
                                                                                                                                                ## datasetName: string (required)
                                                                                                                                                ##              
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## name 
                                                                                                                                                ## of 
                                                                                                                                                ## the 
                                                                                                                                                ## data 
                                                                                                                                                ## set.
  var path_402656589 = newJObject()
  add(path_402656589, "datasetName", newJString(datasetName))
  result = call_402656588.call(path_402656589, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_402656576(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_402656577, base: "/",
    makeUrl: url_CreateDatasetContent_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_402656560 = ref object of OpenApiRestCall_402656044
proc url_GetDatasetContent_402656562(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetDatasetContent_402656561(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656563 = path.getOrDefault("datasetName")
  valid_402656563 = validateParameter(valid_402656563, JString, required = true,
                                      default = nil)
  if valid_402656563 != nil:
    section.add "datasetName", valid_402656563
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
                                  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_402656564 = query.getOrDefault("versionId")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "versionId", valid_402656564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656565 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Security-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_GetDatasetContent_402656560;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
                                                                                         ## 
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_GetDatasetContent_402656560;
           datasetName: string; versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
                                                             ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   
                                                                                                                                                                                                                                                                                                                                            ## datasetName: string (required)
                                                                                                                                                                                                                                                                                                                                            ##              
                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                            ## data 
                                                                                                                                                                                                                                                                                                                                            ## set 
                                                                                                                                                                                                                                                                                                                                            ## whose 
                                                                                                                                                                                                                                                                                                                                            ## contents 
                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                            ## retrieved.
  var path_402656574 = newJObject()
  var query_402656575 = newJObject()
  add(query_402656575, "versionId", newJString(versionId))
  add(path_402656574, "datasetName", newJString(datasetName))
  result = call_402656573.call(path_402656574, query_402656575, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_402656560(
    name: "getDatasetContent", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_402656561, base: "/",
    makeUrl: url_GetDatasetContent_402656562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_402656590 = ref object of OpenApiRestCall_402656044
proc url_DeleteDatasetContent_402656592(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteDatasetContent_402656591(path: JsonNode; query: JsonNode;
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
  var valid_402656593 = path.getOrDefault("datasetName")
  valid_402656593 = validateParameter(valid_402656593, JString, required = true,
                                      default = nil)
  if valid_402656593 != nil:
    section.add "datasetName", valid_402656593
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
                                  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_402656594 = query.getOrDefault("versionId")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "versionId", valid_402656594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656595 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Security-Token", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Signature")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Signature", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Algorithm", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Date")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Date", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Credential")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Credential", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656602: Call_DeleteDatasetContent_402656590;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the content of the specified data set.
                                                                                         ## 
  let valid = call_402656602.validator(path, query, header, formData, body, _)
  let scheme = call_402656602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656602.makeUrl(scheme.get, call_402656602.host, call_402656602.base,
                                   call_402656602.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656602, uri, valid, _)

proc call*(call_402656603: Call_DeleteDatasetContent_402656590;
           datasetName: string; versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
                                                   ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   
                                                                                                                                                                                                                                                                                                            ## datasetName: string (required)
                                                                                                                                                                                                                                                                                                            ##              
                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                            ## data 
                                                                                                                                                                                                                                                                                                            ## set 
                                                                                                                                                                                                                                                                                                            ## whose 
                                                                                                                                                                                                                                                                                                            ## content 
                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                            ## deleted.
  var path_402656604 = newJObject()
  var query_402656605 = newJObject()
  add(query_402656605, "versionId", newJString(versionId))
  add(path_402656604, "datasetName", newJString(datasetName))
  result = call_402656603.call(path_402656604, query_402656605, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_402656590(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_402656591, base: "/",
    makeUrl: url_DeleteDatasetContent_402656592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_402656621 = ref object of OpenApiRestCall_402656044
proc url_CreateDatastore_402656623(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatastore_402656622(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656624 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Security-Token", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Signature")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Signature", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Algorithm", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Date")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Date", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Credential")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Credential", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656630
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

proc call*(call_402656632: Call_CreateDatastore_402656621; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a data store, which is a repository for messages.
                                                                                         ## 
  let valid = call_402656632.validator(path, query, header, formData, body, _)
  let scheme = call_402656632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656632.makeUrl(scheme.get, call_402656632.host, call_402656632.base,
                                   call_402656632.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656632, uri, valid, _)

proc call*(call_402656633: Call_CreateDatastore_402656621; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_402656634 = newJObject()
  if body != nil:
    body_402656634 = body
  result = call_402656633.call(nil, nil, nil, nil, body_402656634)

var createDatastore* = Call_CreateDatastore_402656621(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_402656622,
    base: "/", makeUrl: url_CreateDatastore_402656623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_402656606 = ref object of OpenApiRestCall_402656044
proc url_ListDatastores_402656608(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatastores_402656607(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                                                   ## nextToken: JString
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## token 
                                                                                                                                                   ## for 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## set 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  section = newJObject()
  var valid_402656609 = query.getOrDefault("maxResults")
  valid_402656609 = validateParameter(valid_402656609, JInt, required = false,
                                      default = nil)
  if valid_402656609 != nil:
    section.add "maxResults", valid_402656609
  var valid_402656610 = query.getOrDefault("nextToken")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "nextToken", valid_402656610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656611 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Security-Token", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Signature")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Signature", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Algorithm", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Date")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Date", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Credential")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Credential", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656618: Call_ListDatastores_402656606; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of data stores.
                                                                                         ## 
  let valid = call_402656618.validator(path, query, header, formData, body, _)
  let scheme = call_402656618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656618.makeUrl(scheme.get, call_402656618.host, call_402656618.base,
                                   call_402656618.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656618, uri, valid, _)

proc call*(call_402656619: Call_ListDatastores_402656606; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   maxResults: int
                                     ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                      ## nextToken: string
                                                                                                                                                      ##            
                                                                                                                                                      ## : 
                                                                                                                                                      ## The 
                                                                                                                                                      ## token 
                                                                                                                                                      ## for 
                                                                                                                                                      ## the 
                                                                                                                                                      ## next 
                                                                                                                                                      ## set 
                                                                                                                                                      ## of 
                                                                                                                                                      ## results.
  var query_402656620 = newJObject()
  add(query_402656620, "maxResults", newJInt(maxResults))
  add(query_402656620, "nextToken", newJString(nextToken))
  result = call_402656619.call(nil, query_402656620, nil, nil, nil)

var listDatastores* = Call_ListDatastores_402656606(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_402656607,
    base: "/", makeUrl: url_ListDatastores_402656608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_402656650 = ref object of OpenApiRestCall_402656044
proc url_CreatePipeline_402656652(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_402656651(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656653 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Security-Token", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Signature")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Signature", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Algorithm", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Date")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Date", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Credential")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Credential", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656659
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

proc call*(call_402656661: Call_CreatePipeline_402656650; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_CreatePipeline_402656650; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   
                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656663 = newJObject()
  if body != nil:
    body_402656663 = body
  result = call_402656662.call(nil, nil, nil, nil, body_402656663)

var createPipeline* = Call_CreatePipeline_402656650(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_402656651,
    base: "/", makeUrl: url_CreatePipeline_402656652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_402656635 = ref object of OpenApiRestCall_402656044
proc url_ListPipelines_402656637(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_402656636(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of pipelines.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                   ## nextToken: JString
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## token 
                                                                                                                                                   ## for 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## set 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  section = newJObject()
  var valid_402656638 = query.getOrDefault("maxResults")
  valid_402656638 = validateParameter(valid_402656638, JInt, required = false,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "maxResults", valid_402656638
  var valid_402656639 = query.getOrDefault("nextToken")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "nextToken", valid_402656639
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656640 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Security-Token", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Signature")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Signature", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Algorithm", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Date")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Date", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Credential")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Credential", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656647: Call_ListPipelines_402656635; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of pipelines.
                                                                                         ## 
  let valid = call_402656647.validator(path, query, header, formData, body, _)
  let scheme = call_402656647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656647.makeUrl(scheme.get, call_402656647.host, call_402656647.base,
                                   call_402656647.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656647, uri, valid, _)

proc call*(call_402656648: Call_ListPipelines_402656635; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   maxResults: int
                                   ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   
                                                                                                                                                    ## nextToken: string
                                                                                                                                                    ##            
                                                                                                                                                    ## : 
                                                                                                                                                    ## The 
                                                                                                                                                    ## token 
                                                                                                                                                    ## for 
                                                                                                                                                    ## the 
                                                                                                                                                    ## next 
                                                                                                                                                    ## set 
                                                                                                                                                    ## of 
                                                                                                                                                    ## results.
  var query_402656649 = newJObject()
  add(query_402656649, "maxResults", newJInt(maxResults))
  add(query_402656649, "nextToken", newJString(nextToken))
  result = call_402656648.call(nil, query_402656649, nil, nil, nil)

var listPipelines* = Call_ListPipelines_402656635(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_402656636, base: "/",
    makeUrl: url_ListPipelines_402656637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_402656680 = ref object of OpenApiRestCall_402656044
proc url_UpdateChannel_402656682(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_402656681(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656683 = path.getOrDefault("channelName")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "channelName", valid_402656683
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Security-Token", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Signature")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Signature", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Algorithm", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Date")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Date", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Credential")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Credential", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656690
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

proc call*(call_402656692: Call_UpdateChannel_402656680; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a channel.
                                                                                         ## 
  let valid = call_402656692.validator(path, query, header, formData, body, _)
  let scheme = call_402656692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656692.makeUrl(scheme.get, call_402656692.host, call_402656692.base,
                                   call_402656692.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656692, uri, valid, _)

proc call*(call_402656693: Call_UpdateChannel_402656680; channelName: string;
           body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
                                       ##              : The name of the channel to be updated.
  ##   
                                                                                               ## body: JObject (required)
  var path_402656694 = newJObject()
  var body_402656695 = newJObject()
  add(path_402656694, "channelName", newJString(channelName))
  if body != nil:
    body_402656695 = body
  result = call_402656693.call(path_402656694, nil, nil, nil, body_402656695)

var updateChannel* = Call_UpdateChannel_402656680(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_402656681,
    base: "/", makeUrl: url_UpdateChannel_402656682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_402656664 = ref object of OpenApiRestCall_402656044
proc url_DescribeChannel_402656666(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_DescribeChannel_402656665(path: JsonNode; query: JsonNode;
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
  var valid_402656667 = path.getOrDefault("channelName")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "channelName", valid_402656667
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
                                  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_402656668 = query.getOrDefault("includeStatistics")
  valid_402656668 = validateParameter(valid_402656668, JBool, required = false,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "includeStatistics", valid_402656668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656669 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Security-Token", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Signature")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Signature", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Algorithm", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Date")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Date", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Credential")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Credential", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656676: Call_DescribeChannel_402656664; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a channel.
                                                                                         ## 
  let valid = call_402656676.validator(path, query, header, formData, body, _)
  let scheme = call_402656676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656676.makeUrl(scheme.get, call_402656676.host, call_402656676.base,
                                   call_402656676.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656676, uri, valid, _)

proc call*(call_402656677: Call_DescribeChannel_402656664; channelName: string;
           includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
                                           ##              : The name of the channel whose information is retrieved.
  ##   
                                                                                                                    ## includeStatistics: bool
                                                                                                                    ##                    
                                                                                                                    ## : 
                                                                                                                    ## If 
                                                                                                                    ## true, 
                                                                                                                    ## additional 
                                                                                                                    ## statistical 
                                                                                                                    ## information 
                                                                                                                    ## about 
                                                                                                                    ## the 
                                                                                                                    ## channel 
                                                                                                                    ## is 
                                                                                                                    ## included 
                                                                                                                    ## in 
                                                                                                                    ## the 
                                                                                                                    ## response. 
                                                                                                                    ## This 
                                                                                                                    ## feature 
                                                                                                                    ## cannot 
                                                                                                                    ## be 
                                                                                                                    ## used 
                                                                                                                    ## with 
                                                                                                                    ## a 
                                                                                                                    ## channel 
                                                                                                                    ## whose 
                                                                                                                    ## S3 
                                                                                                                    ## storage 
                                                                                                                    ## is 
                                                                                                                    ## customer-managed.
  var path_402656678 = newJObject()
  var query_402656679 = newJObject()
  add(path_402656678, "channelName", newJString(channelName))
  add(query_402656679, "includeStatistics", newJBool(includeStatistics))
  result = call_402656677.call(path_402656678, query_402656679, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_402656664(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_402656665,
    base: "/", makeUrl: url_DescribeChannel_402656666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_402656696 = ref object of OpenApiRestCall_402656044
proc url_DeleteChannel_402656698(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_402656697(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656699 = path.getOrDefault("channelName")
  valid_402656699 = validateParameter(valid_402656699, JString, required = true,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "channelName", valid_402656699
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656700 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Security-Token", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Signature")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Signature", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Algorithm", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Date")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Date", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Credential")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Credential", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656707: Call_DeleteChannel_402656696; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified channel.
                                                                                         ## 
  let valid = call_402656707.validator(path, query, header, formData, body, _)
  let scheme = call_402656707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656707.makeUrl(scheme.get, call_402656707.host, call_402656707.base,
                                   call_402656707.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656707, uri, valid, _)

proc call*(call_402656708: Call_DeleteChannel_402656696; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
                                   ##              : The name of the channel to delete.
  var path_402656709 = newJObject()
  add(path_402656709, "channelName", newJString(channelName))
  result = call_402656708.call(path_402656709, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_402656696(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_402656697,
    base: "/", makeUrl: url_DeleteChannel_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_402656724 = ref object of OpenApiRestCall_402656044
proc url_UpdateDataset_402656726(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataset_402656725(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656727 = path.getOrDefault("datasetName")
  valid_402656727 = validateParameter(valid_402656727, JString, required = true,
                                      default = nil)
  if valid_402656727 != nil:
    section.add "datasetName", valid_402656727
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656728 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Security-Token", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Signature")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Signature", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Algorithm", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Date")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Date", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Credential")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Credential", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656734
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

proc call*(call_402656736: Call_UpdateDataset_402656724; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a data set.
                                                                                         ## 
  let valid = call_402656736.validator(path, query, header, formData, body, _)
  let scheme = call_402656736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656736.makeUrl(scheme.get, call_402656736.host, call_402656736.base,
                                   call_402656736.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656736, uri, valid, _)

proc call*(call_402656737: Call_UpdateDataset_402656724; body: JsonNode;
           datasetName: string): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   body: JObject (required)
  ##   datasetName: string (required)
                               ##              : The name of the data set to update.
  var path_402656738 = newJObject()
  var body_402656739 = newJObject()
  if body != nil:
    body_402656739 = body
  add(path_402656738, "datasetName", newJString(datasetName))
  result = call_402656737.call(path_402656738, nil, nil, nil, body_402656739)

var updateDataset* = Call_UpdateDataset_402656724(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_402656725,
    base: "/", makeUrl: url_UpdateDataset_402656726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_402656710 = ref object of OpenApiRestCall_402656044
proc url_DescribeDataset_402656712(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_DescribeDataset_402656711(path: JsonNode; query: JsonNode;
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
  var valid_402656713 = path.getOrDefault("datasetName")
  valid_402656713 = validateParameter(valid_402656713, JString, required = true,
                                      default = nil)
  if valid_402656713 != nil:
    section.add "datasetName", valid_402656713
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656714 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Security-Token", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Signature")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Signature", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Algorithm", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Date")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Date", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Credential")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Credential", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656721: Call_DescribeDataset_402656710; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a data set.
                                                                                         ## 
  let valid = call_402656721.validator(path, query, header, formData, body, _)
  let scheme = call_402656721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656721.makeUrl(scheme.get, call_402656721.host, call_402656721.base,
                                   call_402656721.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656721, uri, valid, _)

proc call*(call_402656722: Call_DescribeDataset_402656710; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
                                            ##              : The name of the data set whose information is retrieved.
  var path_402656723 = newJObject()
  add(path_402656723, "datasetName", newJString(datasetName))
  result = call_402656722.call(path_402656723, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_402656710(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_402656711,
    base: "/", makeUrl: url_DescribeDataset_402656712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_402656740 = ref object of OpenApiRestCall_402656044
proc url_DeleteDataset_402656742(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_402656741(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656743 = path.getOrDefault("datasetName")
  valid_402656743 = validateParameter(valid_402656743, JString, required = true,
                                      default = nil)
  if valid_402656743 != nil:
    section.add "datasetName", valid_402656743
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Security-Token", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Signature")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Signature", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Algorithm", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Date")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Date", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Credential")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Credential", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656751: Call_DeleteDataset_402656740; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
                                                                                         ## 
  let valid = call_402656751.validator(path, query, header, formData, body, _)
  let scheme = call_402656751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656751.makeUrl(scheme.get, call_402656751.host, call_402656751.base,
                                   call_402656751.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656751, uri, valid, _)

proc call*(call_402656752: Call_DeleteDataset_402656740; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   
                                                                                                                                           ## datasetName: string (required)
                                                                                                                                           ##              
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## data 
                                                                                                                                           ## set 
                                                                                                                                           ## to 
                                                                                                                                           ## delete.
  var path_402656753 = newJObject()
  add(path_402656753, "datasetName", newJString(datasetName))
  result = call_402656752.call(path_402656753, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_402656740(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_402656741,
    base: "/", makeUrl: url_DeleteDataset_402656742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_402656770 = ref object of OpenApiRestCall_402656044
proc url_UpdateDatastore_402656772(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_UpdateDatastore_402656771(path: JsonNode; query: JsonNode;
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
  var valid_402656773 = path.getOrDefault("datastoreName")
  valid_402656773 = validateParameter(valid_402656773, JString, required = true,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "datastoreName", valid_402656773
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656774 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Security-Token", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Signature")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Signature", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Algorithm", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Date")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Date", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Credential")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Credential", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656780
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

proc call*(call_402656782: Call_UpdateDatastore_402656770; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a data store.
                                                                                         ## 
  let valid = call_402656782.validator(path, query, header, formData, body, _)
  let scheme = call_402656782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656782.makeUrl(scheme.get, call_402656782.host, call_402656782.base,
                                   call_402656782.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656782, uri, valid, _)

proc call*(call_402656783: Call_UpdateDatastore_402656770; body: JsonNode;
           datastoreName: string): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   body: JObject (required)
  ##   datastoreName: string (required)
                               ##                : The name of the data store to be updated.
  var path_402656784 = newJObject()
  var body_402656785 = newJObject()
  if body != nil:
    body_402656785 = body
  add(path_402656784, "datastoreName", newJString(datastoreName))
  result = call_402656783.call(path_402656784, nil, nil, nil, body_402656785)

var updateDatastore* = Call_UpdateDatastore_402656770(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_402656771,
    base: "/", makeUrl: url_UpdateDatastore_402656772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_402656754 = ref object of OpenApiRestCall_402656044
proc url_DescribeDatastore_402656756(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeDatastore_402656755(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656757 = path.getOrDefault("datastoreName")
  valid_402656757 = validateParameter(valid_402656757, JString, required = true,
                                      default = nil)
  if valid_402656757 != nil:
    section.add "datastoreName", valid_402656757
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
                                  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_402656758 = query.getOrDefault("includeStatistics")
  valid_402656758 = validateParameter(valid_402656758, JBool, required = false,
                                      default = nil)
  if valid_402656758 != nil:
    section.add "includeStatistics", valid_402656758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Signature")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Signature", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Algorithm", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Date")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Date", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Credential")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Credential", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656766: Call_DescribeDatastore_402656754;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a data store.
                                                                                         ## 
  let valid = call_402656766.validator(path, query, header, formData, body, _)
  let scheme = call_402656766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656766.makeUrl(scheme.get, call_402656766.host, call_402656766.base,
                                   call_402656766.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656766, uri, valid, _)

proc call*(call_402656767: Call_DescribeDatastore_402656754;
           datastoreName: string; includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   includeStatistics: bool
                                              ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  ##   
                                                                                                                                                                                                                                                       ## datastoreName: string (required)
                                                                                                                                                                                                                                                       ##                
                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## data 
                                                                                                                                                                                                                                                       ## store
  var path_402656768 = newJObject()
  var query_402656769 = newJObject()
  add(query_402656769, "includeStatistics", newJBool(includeStatistics))
  add(path_402656768, "datastoreName", newJString(datastoreName))
  result = call_402656767.call(path_402656768, query_402656769, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_402656754(
    name: "describeDatastore", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datastores/{datastoreName}",
    validator: validate_DescribeDatastore_402656755, base: "/",
    makeUrl: url_DescribeDatastore_402656756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_402656786 = ref object of OpenApiRestCall_402656044
proc url_DeleteDatastore_402656788(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_DeleteDatastore_402656787(path: JsonNode; query: JsonNode;
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
  var valid_402656789 = path.getOrDefault("datastoreName")
  valid_402656789 = validateParameter(valid_402656789, JString, required = true,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "datastoreName", valid_402656789
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656790 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Security-Token", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Signature")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Signature", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Algorithm", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Date")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Date", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Credential")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Credential", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656797: Call_DeleteDatastore_402656786; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified data store.
                                                                                         ## 
  let valid = call_402656797.validator(path, query, header, formData, body, _)
  let scheme = call_402656797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656797.makeUrl(scheme.get, call_402656797.host, call_402656797.base,
                                   call_402656797.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656797, uri, valid, _)

proc call*(call_402656798: Call_DeleteDatastore_402656786; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
                                      ##                : The name of the data store to delete.
  var path_402656799 = newJObject()
  add(path_402656799, "datastoreName", newJString(datastoreName))
  result = call_402656798.call(path_402656799, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_402656786(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_402656787,
    base: "/", makeUrl: url_DeleteDatastore_402656788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_402656814 = ref object of OpenApiRestCall_402656044
proc url_UpdatePipeline_402656816(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_402656815(path: JsonNode; query: JsonNode;
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
  var valid_402656817 = path.getOrDefault("pipelineName")
  valid_402656817 = validateParameter(valid_402656817, JString, required = true,
                                      default = nil)
  if valid_402656817 != nil:
    section.add "pipelineName", valid_402656817
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656818 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Security-Token", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Signature")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Signature", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Algorithm", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Date")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Date", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Credential")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Credential", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656824
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

proc call*(call_402656826: Call_UpdatePipeline_402656814; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
                                                                                         ## 
  let valid = call_402656826.validator(path, query, header, formData, body, _)
  let scheme = call_402656826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656826.makeUrl(scheme.get, call_402656826.host, call_402656826.base,
                                   call_402656826.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656826, uri, valid, _)

proc call*(call_402656827: Call_UpdatePipeline_402656814; pipelineName: string;
           body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   
                                                                                                                                                                                                                              ## pipelineName: string (required)
                                                                                                                                                                                                                              ##               
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                              ## name 
                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                              ## pipeline 
                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                              ## update.
  ##   
                                                                                                                                                                                                                                        ## body: JObject (required)
  var path_402656828 = newJObject()
  var body_402656829 = newJObject()
  add(path_402656828, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_402656829 = body
  result = call_402656827.call(path_402656828, nil, nil, nil, body_402656829)

var updatePipeline* = Call_UpdatePipeline_402656814(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_402656815,
    base: "/", makeUrl: url_UpdatePipeline_402656816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_402656800 = ref object of OpenApiRestCall_402656044
proc url_DescribePipeline_402656802(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DescribePipeline_402656801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656803 = path.getOrDefault("pipelineName")
  valid_402656803 = validateParameter(valid_402656803, JString, required = true,
                                      default = nil)
  if valid_402656803 != nil:
    section.add "pipelineName", valid_402656803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656804 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Security-Token", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Signature")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Signature", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Algorithm", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Date")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Date", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Credential")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Credential", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656811: Call_DescribePipeline_402656800;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a pipeline.
                                                                                         ## 
  let valid = call_402656811.validator(path, query, header, formData, body, _)
  let scheme = call_402656811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656811.makeUrl(scheme.get, call_402656811.host, call_402656811.base,
                                   call_402656811.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656811, uri, valid, _)

proc call*(call_402656812: Call_DescribePipeline_402656800; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
                                            ##               : The name of the pipeline whose information is retrieved.
  var path_402656813 = newJObject()
  add(path_402656813, "pipelineName", newJString(pipelineName))
  result = call_402656812.call(path_402656813, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_402656800(
    name: "describePipeline", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/pipelines/{pipelineName}",
    validator: validate_DescribePipeline_402656801, base: "/",
    makeUrl: url_DescribePipeline_402656802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_402656830 = ref object of OpenApiRestCall_402656044
proc url_DeletePipeline_402656832(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_402656831(path: JsonNode; query: JsonNode;
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
  var valid_402656833 = path.getOrDefault("pipelineName")
  valid_402656833 = validateParameter(valid_402656833, JString, required = true,
                                      default = nil)
  if valid_402656833 != nil:
    section.add "pipelineName", valid_402656833
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656834 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Security-Token", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Signature")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Signature", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Algorithm", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Date")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Date", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Credential")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Credential", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656841: Call_DeletePipeline_402656830; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified pipeline.
                                                                                         ## 
  let valid = call_402656841.validator(path, query, header, formData, body, _)
  let scheme = call_402656841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656841.makeUrl(scheme.get, call_402656841.host, call_402656841.base,
                                   call_402656841.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656841, uri, valid, _)

proc call*(call_402656842: Call_DeletePipeline_402656830; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
                                    ##               : The name of the pipeline to delete.
  var path_402656843 = newJObject()
  add(path_402656843, "pipelineName", newJString(pipelineName))
  result = call_402656842.call(path_402656843, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_402656830(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_402656831,
    base: "/", makeUrl: url_DeletePipeline_402656832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_402656856 = ref object of OpenApiRestCall_402656044
proc url_PutLoggingOptions_402656858(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_402656857(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656859 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Security-Token", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Signature")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Signature", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Algorithm", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Date")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Date", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Credential")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Credential", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656865
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

proc call*(call_402656867: Call_PutLoggingOptions_402656856;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
                                                                                         ## 
  let valid = call_402656867.validator(path, query, header, formData, body, _)
  let scheme = call_402656867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656867.makeUrl(scheme.get, call_402656867.host, call_402656867.base,
                                   call_402656867.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656867, uri, valid, _)

proc call*(call_402656868: Call_PutLoggingOptions_402656856; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656869 = newJObject()
  if body != nil:
    body_402656869 = body
  result = call_402656868.call(nil, nil, nil, nil, body_402656869)

var putLoggingOptions* = Call_PutLoggingOptions_402656856(
    name: "putLoggingOptions", meth: HttpMethod.HttpPut,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_402656857, base: "/",
    makeUrl: url_PutLoggingOptions_402656858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_402656844 = ref object of OpenApiRestCall_402656044
proc url_DescribeLoggingOptions_402656846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_402656845(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656847 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Security-Token", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Signature")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Signature", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Algorithm", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Date")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Date", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Credential")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Credential", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656854: Call_DescribeLoggingOptions_402656844;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
                                                                                         ## 
  let valid = call_402656854.validator(path, query, header, formData, body, _)
  let scheme = call_402656854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656854.makeUrl(scheme.get, call_402656854.host, call_402656854.base,
                                   call_402656854.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656854, uri, valid, _)

proc call*(call_402656855: Call_DescribeLoggingOptions_402656844): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_402656855.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_402656844(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_402656845, base: "/",
    makeUrl: url_DescribeLoggingOptions_402656846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_402656870 = ref object of OpenApiRestCall_402656044
proc url_ListDatasetContents_402656872(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListDatasetContents_402656871(path: JsonNode; query: JsonNode;
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
  var valid_402656873 = path.getOrDefault("datasetName")
  valid_402656873 = validateParameter(valid_402656873, JString, required = true,
                                      default = nil)
  if valid_402656873 != nil:
    section.add "datasetName", valid_402656873
  result.add "path", section
  ## parameters in `query` object:
  ##   scheduledBefore: JString
                                  ##                  : A filter to limit results to those data set contents whose creation is scheduled before the given time. See the field <code>triggers.schedule</code> in the CreateDataset request. (timestamp)
  ##   
                                                                                                                                                                                                                                                      ## scheduledOnOrAfter: JString
                                                                                                                                                                                                                                                      ##                     
                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                      ## A 
                                                                                                                                                                                                                                                      ## filter 
                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                      ## limit 
                                                                                                                                                                                                                                                      ## results 
                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                      ## those 
                                                                                                                                                                                                                                                      ## data 
                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                      ## contents 
                                                                                                                                                                                                                                                      ## whose 
                                                                                                                                                                                                                                                      ## creation 
                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                      ## scheduled 
                                                                                                                                                                                                                                                      ## on 
                                                                                                                                                                                                                                                      ## or 
                                                                                                                                                                                                                                                      ## after 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## given 
                                                                                                                                                                                                                                                      ## time. 
                                                                                                                                                                                                                                                      ## See 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## field 
                                                                                                                                                                                                                                                      ## <code>triggers.schedule</code> 
                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## CreateDataset 
                                                                                                                                                                                                                                                      ## request. 
                                                                                                                                                                                                                                                      ## (timestamp)
  ##   
                                                                                                                                                                                                                                                                    ## maxResults: JInt
                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                    ## results 
                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                    ## request.
  ##   
                                                                                                                                                                                                                                                                               ## nextToken: JString
                                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                               ## token 
                                                                                                                                                                                                                                                                               ## for 
                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                               ## next 
                                                                                                                                                                                                                                                                               ## set 
                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                               ## results.
  section = newJObject()
  var valid_402656874 = query.getOrDefault("scheduledBefore")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "scheduledBefore", valid_402656874
  var valid_402656875 = query.getOrDefault("scheduledOnOrAfter")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "scheduledOnOrAfter", valid_402656875
  var valid_402656876 = query.getOrDefault("maxResults")
  valid_402656876 = validateParameter(valid_402656876, JInt, required = false,
                                      default = nil)
  if valid_402656876 != nil:
    section.add "maxResults", valid_402656876
  var valid_402656877 = query.getOrDefault("nextToken")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "nextToken", valid_402656877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656878 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Security-Token", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Signature")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Signature", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Algorithm", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Date")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Date", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Credential")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Credential", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656885: Call_ListDatasetContents_402656870;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about data set contents that have been created.
                                                                                         ## 
  let valid = call_402656885.validator(path, query, header, formData, body, _)
  let scheme = call_402656885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656885.makeUrl(scheme.get, call_402656885.host, call_402656885.base,
                                   call_402656885.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656885, uri, valid, _)

proc call*(call_402656886: Call_ListDatasetContents_402656870;
           datasetName: string; scheduledBefore: string = "";
           scheduledOnOrAfter: string = ""; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listDatasetContents
  ## Lists information about data set contents that have been created.
  ##   
                                                                      ## scheduledBefore: string
                                                                      ##                  
                                                                      ## : 
                                                                      ## A 
                                                                      ## filter to limit 
                                                                      ## results 
                                                                      ## to 
                                                                      ## those data set 
                                                                      ## contents 
                                                                      ## whose 
                                                                      ## creation 
                                                                      ## is 
                                                                      ## scheduled 
                                                                      ## before 
                                                                      ## the 
                                                                      ## given 
                                                                      ## time. 
                                                                      ## See 
                                                                      ## the 
                                                                      ## field 
                                                                      ## <code>triggers.schedule</code> 
                                                                      ## in 
                                                                      ## the 
                                                                      ## CreateDataset 
                                                                      ## request. 
                                                                      ## (timestamp)
  ##   
                                                                                    ## scheduledOnOrAfter: string
                                                                                    ##                     
                                                                                    ## : 
                                                                                    ## A 
                                                                                    ## filter 
                                                                                    ## to 
                                                                                    ## limit 
                                                                                    ## results 
                                                                                    ## to 
                                                                                    ## those 
                                                                                    ## data 
                                                                                    ## set 
                                                                                    ## contents 
                                                                                    ## whose 
                                                                                    ## creation 
                                                                                    ## is 
                                                                                    ## scheduled 
                                                                                    ## on 
                                                                                    ## or 
                                                                                    ## after 
                                                                                    ## the 
                                                                                    ## given 
                                                                                    ## time. 
                                                                                    ## See 
                                                                                    ## the 
                                                                                    ## field 
                                                                                    ## <code>triggers.schedule</code> 
                                                                                    ## in 
                                                                                    ## the 
                                                                                    ## CreateDataset 
                                                                                    ## request. 
                                                                                    ## (timestamp)
  ##   
                                                                                                  ## maxResults: int
                                                                                                  ##             
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## maximum 
                                                                                                  ## number 
                                                                                                  ## of 
                                                                                                  ## results 
                                                                                                  ## to 
                                                                                                  ## return 
                                                                                                  ## in 
                                                                                                  ## this 
                                                                                                  ## request.
  ##   
                                                                                                             ## nextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## token 
                                                                                                             ## for 
                                                                                                             ## the 
                                                                                                             ## next 
                                                                                                             ## set 
                                                                                                             ## of 
                                                                                                             ## results.
  ##   
                                                                                                                        ## datasetName: string (required)
                                                                                                                        ##              
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## name 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## data 
                                                                                                                        ## set 
                                                                                                                        ## whose 
                                                                                                                        ## contents 
                                                                                                                        ## information 
                                                                                                                        ## you 
                                                                                                                        ## want 
                                                                                                                        ## to 
                                                                                                                        ## list.
  var path_402656887 = newJObject()
  var query_402656888 = newJObject()
  add(query_402656888, "scheduledBefore", newJString(scheduledBefore))
  add(query_402656888, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(query_402656888, "maxResults", newJInt(maxResults))
  add(query_402656888, "nextToken", newJString(nextToken))
  add(path_402656887, "datasetName", newJString(datasetName))
  result = call_402656886.call(path_402656887, query_402656888, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_402656870(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_402656871, base: "/",
    makeUrl: url_ListDatasetContents_402656872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656903 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656905(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656904(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656906 = query.getOrDefault("resourceArn")
  valid_402656906 = validateParameter(valid_402656906, JString, required = true,
                                      default = nil)
  if valid_402656906 != nil:
    section.add "resourceArn", valid_402656906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656907 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Security-Token", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Signature")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Signature", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Algorithm", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Date")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Date", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Credential")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Credential", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656913
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

proc call*(call_402656915: Call_TagResource_402656903; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
                                                                                         ## 
  let valid = call_402656915.validator(path, query, header, formData, body, _)
  let scheme = call_402656915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656915.makeUrl(scheme.get, call_402656915.host, call_402656915.base,
                                   call_402656915.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656915, uri, valid, _)

proc call*(call_402656916: Call_TagResource_402656903; resourceArn: string;
           body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   
                                                                                                                  ## resourceArn: string (required)
                                                                                                                  ##              
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## ARN 
                                                                                                                  ## of 
                                                                                                                  ## the 
                                                                                                                  ## resource 
                                                                                                                  ## whose 
                                                                                                                  ## tags 
                                                                                                                  ## you 
                                                                                                                  ## want 
                                                                                                                  ## to 
                                                                                                                  ## modify.
  ##   
                                                                                                                            ## body: JObject (required)
  var query_402656917 = newJObject()
  var body_402656918 = newJObject()
  add(query_402656917, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_402656918 = body
  result = call_402656916.call(nil, query_402656917, nil, nil, body_402656918)

var tagResource* = Call_TagResource_402656903(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn", validator: validate_TagResource_402656904,
    base: "/", makeUrl: url_TagResource_402656905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656889 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656891(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656890(path: JsonNode; query: JsonNode;
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
  var valid_402656892 = query.getOrDefault("resourceArn")
  valid_402656892 = validateParameter(valid_402656892, JString, required = true,
                                      default = nil)
  if valid_402656892 != nil:
    section.add "resourceArn", valid_402656892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656893 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Security-Token", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Signature")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Signature", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Algorithm", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Date")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Date", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Credential")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Credential", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656900: Call_ListTagsForResource_402656889;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
                                                                                         ## 
  let valid = call_402656900.validator(path, query, header, formData, body, _)
  let scheme = call_402656900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656900.makeUrl(scheme.get, call_402656900.host, call_402656900.base,
                                   call_402656900.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656900, uri, valid, _)

proc call*(call_402656901: Call_ListTagsForResource_402656889;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   
                                                                       ## resourceArn: string (required)
                                                                       ##              
                                                                       ## : 
                                                                       ## The ARN of the 
                                                                       ## resource 
                                                                       ## whose 
                                                                       ## tags 
                                                                       ## you 
                                                                       ## want to 
                                                                       ## list.
  var query_402656902 = newJObject()
  add(query_402656902, "resourceArn", newJString(resourceArn))
  result = call_402656901.call(nil, query_402656902, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656889(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_402656890, base: "/",
    makeUrl: url_ListTagsForResource_402656891,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_402656919 = ref object of OpenApiRestCall_402656044
proc url_RunPipelineActivity_402656921(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RunPipelineActivity_402656920(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656922 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Security-Token", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Signature")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Signature", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Algorithm", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Date")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Date", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Credential")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Credential", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656928
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

proc call*(call_402656930: Call_RunPipelineActivity_402656919;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
                                                                                         ## 
  let valid = call_402656930.validator(path, query, header, formData, body, _)
  let scheme = call_402656930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656930.makeUrl(scheme.get, call_402656930.host, call_402656930.base,
                                   call_402656930.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656930, uri, valid, _)

proc call*(call_402656931: Call_RunPipelineActivity_402656919; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   
                                                                               ## body: JObject (required)
  var body_402656932 = newJObject()
  if body != nil:
    body_402656932 = body
  result = call_402656931.call(nil, nil, nil, nil, body_402656932)

var runPipelineActivity* = Call_RunPipelineActivity_402656919(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_402656920, base: "/",
    makeUrl: url_RunPipelineActivity_402656921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_402656933 = ref object of OpenApiRestCall_402656044
proc url_SampleChannelData_402656935(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_SampleChannelData_402656934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656936 = path.getOrDefault("channelName")
  valid_402656936 = validateParameter(valid_402656936, JString, required = true,
                                      default = nil)
  if valid_402656936 != nil:
    section.add "channelName", valid_402656936
  result.add "path", section
  ## parameters in `query` object:
  ##   maxMessages: JInt
                                  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   
                                                                                                                                           ## endTime: JString
                                                                                                                                           ##          
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## end 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## time 
                                                                                                                                           ## window 
                                                                                                                                           ## from 
                                                                                                                                           ## which 
                                                                                                                                           ## sample 
                                                                                                                                           ## messages 
                                                                                                                                           ## are 
                                                                                                                                           ## retrieved.
  ##   
                                                                                                                                                        ## startTime: JString
                                                                                                                                                        ##            
                                                                                                                                                        ## : 
                                                                                                                                                        ## The 
                                                                                                                                                        ## start 
                                                                                                                                                        ## of 
                                                                                                                                                        ## the 
                                                                                                                                                        ## time 
                                                                                                                                                        ## window 
                                                                                                                                                        ## from 
                                                                                                                                                        ## which 
                                                                                                                                                        ## sample 
                                                                                                                                                        ## messages 
                                                                                                                                                        ## are 
                                                                                                                                                        ## retrieved.
  section = newJObject()
  var valid_402656937 = query.getOrDefault("maxMessages")
  valid_402656937 = validateParameter(valid_402656937, JInt, required = false,
                                      default = nil)
  if valid_402656937 != nil:
    section.add "maxMessages", valid_402656937
  var valid_402656938 = query.getOrDefault("endTime")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "endTime", valid_402656938
  var valid_402656939 = query.getOrDefault("startTime")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "startTime", valid_402656939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656940 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Security-Token", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-Signature")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Signature", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Algorithm", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Date")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Date", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Credential")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Credential", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656947: Call_SampleChannelData_402656933;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
                                                                                         ## 
  let valid = call_402656947.validator(path, query, header, formData, body, _)
  let scheme = call_402656947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656947.makeUrl(scheme.get, call_402656947.host, call_402656947.base,
                                   call_402656947.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656947, uri, valid, _)

proc call*(call_402656948: Call_SampleChannelData_402656933;
           channelName: string; maxMessages: int = 0; endTime: string = "";
           startTime: string = ""): Recallable =
  ## sampleChannelData
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ##   
                                                                                                                                           ## channelName: string (required)
                                                                                                                                           ##              
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## channel 
                                                                                                                                           ## whose 
                                                                                                                                           ## message 
                                                                                                                                           ## samples 
                                                                                                                                           ## are 
                                                                                                                                           ## retrieved.
  ##   
                                                                                                                                                        ## maxMessages: int
                                                                                                                                                        ##              
                                                                                                                                                        ## : 
                                                                                                                                                        ## The 
                                                                                                                                                        ## number 
                                                                                                                                                        ## of 
                                                                                                                                                        ## sample 
                                                                                                                                                        ## messages 
                                                                                                                                                        ## to 
                                                                                                                                                        ## be 
                                                                                                                                                        ## retrieved. 
                                                                                                                                                        ## The 
                                                                                                                                                        ## limit 
                                                                                                                                                        ## is 
                                                                                                                                                        ## 10, 
                                                                                                                                                        ## the 
                                                                                                                                                        ## default 
                                                                                                                                                        ## is 
                                                                                                                                                        ## also 
                                                                                                                                                        ## 10.
  ##   
                                                                                                                                                              ## endTime: string
                                                                                                                                                              ##          
                                                                                                                                                              ## : 
                                                                                                                                                              ## The 
                                                                                                                                                              ## end 
                                                                                                                                                              ## of 
                                                                                                                                                              ## the 
                                                                                                                                                              ## time 
                                                                                                                                                              ## window 
                                                                                                                                                              ## from 
                                                                                                                                                              ## which 
                                                                                                                                                              ## sample 
                                                                                                                                                              ## messages 
                                                                                                                                                              ## are 
                                                                                                                                                              ## retrieved.
  ##   
                                                                                                                                                                           ## startTime: string
                                                                                                                                                                           ##            
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## start 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## time 
                                                                                                                                                                           ## window 
                                                                                                                                                                           ## from 
                                                                                                                                                                           ## which 
                                                                                                                                                                           ## sample 
                                                                                                                                                                           ## messages 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## retrieved.
  var path_402656949 = newJObject()
  var query_402656950 = newJObject()
  add(path_402656949, "channelName", newJString(channelName))
  add(query_402656950, "maxMessages", newJInt(maxMessages))
  add(query_402656950, "endTime", newJString(endTime))
  add(query_402656950, "startTime", newJString(startTime))
  result = call_402656948.call(path_402656949, query_402656950, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_402656933(
    name: "sampleChannelData", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_402656934, base: "/",
    makeUrl: url_SampleChannelData_402656935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_402656951 = ref object of OpenApiRestCall_402656044
proc url_StartPipelineReprocessing_402656953(protocol: Scheme; host: string;
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

proc validate_StartPipelineReprocessing_402656952(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656954 = path.getOrDefault("pipelineName")
  valid_402656954 = validateParameter(valid_402656954, JString, required = true,
                                      default = nil)
  if valid_402656954 != nil:
    section.add "pipelineName", valid_402656954
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656955 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Security-Token", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Signature")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Signature", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Algorithm", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Date")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Date", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Credential")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Credential", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656961
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

proc call*(call_402656963: Call_StartPipelineReprocessing_402656951;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
                                                                                         ## 
  let valid = call_402656963.validator(path, query, header, formData, body, _)
  let scheme = call_402656963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656963.makeUrl(scheme.get, call_402656963.host, call_402656963.base,
                                   call_402656963.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656963, uri, valid, _)

proc call*(call_402656964: Call_StartPipelineReprocessing_402656951;
           pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   
                                                                      ## pipelineName: string (required)
                                                                      ##               
                                                                      ## : 
                                                                      ## The name of the 
                                                                      ## pipeline 
                                                                      ## on 
                                                                      ## which to 
                                                                      ## start 
                                                                      ## reprocessing.
  ##   
                                                                                      ## body: JObject (required)
  var path_402656965 = newJObject()
  var body_402656966 = newJObject()
  add(path_402656965, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_402656966 = body
  result = call_402656964.call(path_402656965, nil, nil, nil, body_402656966)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_402656951(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_402656952, base: "/",
    makeUrl: url_StartPipelineReprocessing_402656953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656967 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656969(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656968(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the given tags (metadata) from the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The keys of those tags which you want to remove.
  ##   
                                                                                                ## resourceArn: JString (required)
                                                                                                ##              
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## ARN 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## resource 
                                                                                                ## whose 
                                                                                                ## tags 
                                                                                                ## you 
                                                                                                ## want 
                                                                                                ## to 
                                                                                                ## remove.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656970 = query.getOrDefault("tagKeys")
  valid_402656970 = validateParameter(valid_402656970, JArray, required = true,
                                      default = nil)
  if valid_402656970 != nil:
    section.add "tagKeys", valid_402656970
  var valid_402656971 = query.getOrDefault("resourceArn")
  valid_402656971 = validateParameter(valid_402656971, JString, required = true,
                                      default = nil)
  if valid_402656971 != nil:
    section.add "resourceArn", valid_402656971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656972 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Security-Token", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Signature")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Signature", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Algorithm", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Date")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Date", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Credential")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Credential", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656979: Call_UntagResource_402656967; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the given tags (metadata) from the resource.
                                                                                         ## 
  let valid = call_402656979.validator(path, query, header, formData, body, _)
  let scheme = call_402656979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656979.makeUrl(scheme.get, call_402656979.host, call_402656979.base,
                                   call_402656979.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656979, uri, valid, _)

proc call*(call_402656980: Call_UntagResource_402656967; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
                                                         ##          : The keys of those tags which you want to remove.
  ##   
                                                                                                                       ## resourceArn: string (required)
                                                                                                                       ##              
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## ARN 
                                                                                                                       ## of 
                                                                                                                       ## the 
                                                                                                                       ## resource 
                                                                                                                       ## whose 
                                                                                                                       ## tags 
                                                                                                                       ## you 
                                                                                                                       ## want 
                                                                                                                       ## to 
                                                                                                                       ## remove.
  var query_402656981 = newJObject()
  if tagKeys != nil:
    query_402656981.add "tagKeys", tagKeys
  add(query_402656981, "resourceArn", newJString(resourceArn))
  result = call_402656980.call(nil, query_402656981, nil, nil, nil)

var untagResource* = Call_UntagResource_402656967(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_402656968,
    base: "/", makeUrl: url_UntagResource_402656969,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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