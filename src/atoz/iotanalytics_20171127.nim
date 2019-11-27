
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
  Call_BatchPutMessage_599705 = ref object of OpenApiRestCall_599368
proc url_BatchPutMessage_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchPutMessage_599706(path: JsonNode; query: JsonNode;
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
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_BatchPutMessage_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_BatchPutMessage_599705; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var batchPutMessage* = Call_BatchPutMessage_599705(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_599706, base: "/",
    url: url_BatchPutMessage_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_599960 = ref object of OpenApiRestCall_599368
proc url_CancelPipelineReprocessing_599962(protocol: Scheme; host: string;
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

proc validate_CancelPipelineReprocessing_599961(path: JsonNode; query: JsonNode;
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
  var valid_599977 = path.getOrDefault("reprocessingId")
  valid_599977 = validateParameter(valid_599977, JString, required = true,
                                 default = nil)
  if valid_599977 != nil:
    section.add "reprocessingId", valid_599977
  var valid_599978 = path.getOrDefault("pipelineName")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "pipelineName", valid_599978
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
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CancelPipelineReprocessing_599960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CancelPipelineReprocessing_599960;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_599988 = newJObject()
  add(path_599988, "reprocessingId", newJString(reprocessingId))
  add(path_599988, "pipelineName", newJString(pipelineName))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_599960(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_599961, base: "/",
    url: url_CancelPipelineReprocessing_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_600005 = ref object of OpenApiRestCall_599368
proc url_CreateChannel_600007(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_600006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600008 = header.getOrDefault("X-Amz-Date")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Date", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Security-Token")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Security-Token", valid_600009
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

proc call*(call_600016: Call_CreateChannel_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreateChannel_600005; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createChannel* = Call_CreateChannel_600005(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_600006, base: "/",
    url: url_CreateChannel_600007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_599990 = ref object of OpenApiRestCall_599368
proc url_ListChannels_599992(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_599991(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599993 = query.getOrDefault("maxResults")
  valid_599993 = validateParameter(valid_599993, JInt, required = false, default = nil)
  if valid_599993 != nil:
    section.add "maxResults", valid_599993
  var valid_599994 = query.getOrDefault("nextToken")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "nextToken", valid_599994
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
  var valid_599995 = header.getOrDefault("X-Amz-Date")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Date", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Security-Token")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Security-Token", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Content-Sha256", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Algorithm")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Algorithm", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Signature")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Signature", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-SignedHeaders", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Credential")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Credential", valid_600001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_ListChannels_599990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_ListChannels_599990; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_600004 = newJObject()
  add(query_600004, "maxResults", newJInt(maxResults))
  add(query_600004, "nextToken", newJString(nextToken))
  result = call_600003.call(nil, query_600004, nil, nil, nil)

var listChannels* = Call_ListChannels_599990(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_599991, base: "/",
    url: url_ListChannels_599992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_600034 = ref object of OpenApiRestCall_599368
proc url_CreateDataset_600036(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataset_600035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_CreateDataset_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_CreateDataset_600034; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_600047 = newJObject()
  if body != nil:
    body_600047 = body
  result = call_600046.call(nil, nil, nil, nil, body_600047)

var createDataset* = Call_CreateDataset_600034(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_600035, base: "/",
    url: url_CreateDataset_600036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_600019 = ref object of OpenApiRestCall_599368
proc url_ListDatasets_600021(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasets_600020(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600022 = query.getOrDefault("maxResults")
  valid_600022 = validateParameter(valid_600022, JInt, required = false, default = nil)
  if valid_600022 != nil:
    section.add "maxResults", valid_600022
  var valid_600023 = query.getOrDefault("nextToken")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "nextToken", valid_600023
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
  var valid_600024 = header.getOrDefault("X-Amz-Date")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Date", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Security-Token")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Security-Token", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_ListDatasets_600019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_ListDatasets_600019; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_600033 = newJObject()
  add(query_600033, "maxResults", newJInt(maxResults))
  add(query_600033, "nextToken", newJString(nextToken))
  result = call_600032.call(nil, query_600033, nil, nil, nil)

var listDatasets* = Call_ListDatasets_600019(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_600020, base: "/",
    url: url_ListDatasets_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_600064 = ref object of OpenApiRestCall_599368
proc url_CreateDatasetContent_600066(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatasetContent_600065(path: JsonNode; query: JsonNode;
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
  var valid_600067 = path.getOrDefault("datasetName")
  valid_600067 = validateParameter(valid_600067, JString, required = true,
                                 default = nil)
  if valid_600067 != nil:
    section.add "datasetName", valid_600067
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
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
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
  if body != nil:
    result.add "body", body

proc call*(call_600075: Call_CreateDatasetContent_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_600075.validator(path, query, header, formData, body)
  let scheme = call_600075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600075.url(scheme.get, call_600075.host, call_600075.base,
                         call_600075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600075, url, valid)

proc call*(call_600076: Call_CreateDatasetContent_600064; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_600077 = newJObject()
  add(path_600077, "datasetName", newJString(datasetName))
  result = call_600076.call(path_600077, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_600064(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_600065, base: "/",
    url: url_CreateDatasetContent_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_600048 = ref object of OpenApiRestCall_599368
proc url_GetDatasetContent_600050(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatasetContent_600049(path: JsonNode; query: JsonNode;
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
  var valid_600051 = path.getOrDefault("datasetName")
  valid_600051 = validateParameter(valid_600051, JString, required = true,
                                 default = nil)
  if valid_600051 != nil:
    section.add "datasetName", valid_600051
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_600052 = query.getOrDefault("versionId")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "versionId", valid_600052
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
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
  if body != nil:
    result.add "body", body

proc call*(call_600060: Call_GetDatasetContent_600048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_600060.validator(path, query, header, formData, body)
  let scheme = call_600060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600060.url(scheme.get, call_600060.host, call_600060.base,
                         call_600060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600060, url, valid)

proc call*(call_600061: Call_GetDatasetContent_600048; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_600062 = newJObject()
  var query_600063 = newJObject()
  add(query_600063, "versionId", newJString(versionId))
  add(path_600062, "datasetName", newJString(datasetName))
  result = call_600061.call(path_600062, query_600063, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_600048(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_600049, base: "/",
    url: url_GetDatasetContent_600050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_600078 = ref object of OpenApiRestCall_599368
proc url_DeleteDatasetContent_600080(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatasetContent_600079(path: JsonNode; query: JsonNode;
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
  var valid_600081 = path.getOrDefault("datasetName")
  valid_600081 = validateParameter(valid_600081, JString, required = true,
                                 default = nil)
  if valid_600081 != nil:
    section.add "datasetName", valid_600081
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_600082 = query.getOrDefault("versionId")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "versionId", valid_600082
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
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
  if body != nil:
    result.add "body", body

proc call*(call_600090: Call_DeleteDatasetContent_600078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_600090.validator(path, query, header, formData, body)
  let scheme = call_600090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600090.url(scheme.get, call_600090.host, call_600090.base,
                         call_600090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600090, url, valid)

proc call*(call_600091: Call_DeleteDatasetContent_600078; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_600092 = newJObject()
  var query_600093 = newJObject()
  add(query_600093, "versionId", newJString(versionId))
  add(path_600092, "datasetName", newJString(datasetName))
  result = call_600091.call(path_600092, query_600093, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_600078(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_600079, base: "/",
    url: url_DeleteDatasetContent_600080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_600109 = ref object of OpenApiRestCall_599368
proc url_CreateDatastore_600111(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatastore_600110(path: JsonNode; query: JsonNode;
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
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_CreateDatastore_600109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_CreateDatastore_600109; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_600122 = newJObject()
  if body != nil:
    body_600122 = body
  result = call_600121.call(nil, nil, nil, nil, body_600122)

var createDatastore* = Call_CreateDatastore_600109(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_600110, base: "/",
    url: url_CreateDatastore_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_600094 = ref object of OpenApiRestCall_599368
proc url_ListDatastores_600096(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatastores_600095(path: JsonNode; query: JsonNode;
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
  var valid_600097 = query.getOrDefault("maxResults")
  valid_600097 = validateParameter(valid_600097, JInt, required = false, default = nil)
  if valid_600097 != nil:
    section.add "maxResults", valid_600097
  var valid_600098 = query.getOrDefault("nextToken")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "nextToken", valid_600098
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
  var valid_600099 = header.getOrDefault("X-Amz-Date")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Date", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Security-Token")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Security-Token", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_ListDatastores_600094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_ListDatastores_600094; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_600108 = newJObject()
  add(query_600108, "maxResults", newJInt(maxResults))
  add(query_600108, "nextToken", newJString(nextToken))
  result = call_600107.call(nil, query_600108, nil, nil, nil)

var listDatastores* = Call_ListDatastores_600094(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_600095, base: "/",
    url: url_ListDatastores_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_600138 = ref object of OpenApiRestCall_599368
proc url_CreatePipeline_600140(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_600139(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600141 = header.getOrDefault("X-Amz-Date")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Date", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Security-Token")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Security-Token", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Content-Sha256", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Algorithm")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Algorithm", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Signature")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Signature", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-SignedHeaders", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Credential")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Credential", valid_600147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600149: Call_CreatePipeline_600138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_600149.validator(path, query, header, formData, body)
  let scheme = call_600149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600149.url(scheme.get, call_600149.host, call_600149.base,
                         call_600149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600149, url, valid)

proc call*(call_600150: Call_CreatePipeline_600138; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_600151 = newJObject()
  if body != nil:
    body_600151 = body
  result = call_600150.call(nil, nil, nil, nil, body_600151)

var createPipeline* = Call_CreatePipeline_600138(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_600139, base: "/",
    url: url_CreatePipeline_600140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_600123 = ref object of OpenApiRestCall_599368
proc url_ListPipelines_600125(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_600124(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600126 = query.getOrDefault("maxResults")
  valid_600126 = validateParameter(valid_600126, JInt, required = false, default = nil)
  if valid_600126 != nil:
    section.add "maxResults", valid_600126
  var valid_600127 = query.getOrDefault("nextToken")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "nextToken", valid_600127
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
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
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
  if body != nil:
    result.add "body", body

proc call*(call_600135: Call_ListPipelines_600123; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_600135.validator(path, query, header, formData, body)
  let scheme = call_600135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600135.url(scheme.get, call_600135.host, call_600135.base,
                         call_600135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600135, url, valid)

proc call*(call_600136: Call_ListPipelines_600123; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_600137 = newJObject()
  add(query_600137, "maxResults", newJInt(maxResults))
  add(query_600137, "nextToken", newJString(nextToken))
  result = call_600136.call(nil, query_600137, nil, nil, nil)

var listPipelines* = Call_ListPipelines_600123(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_600124, base: "/",
    url: url_ListPipelines_600125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_600168 = ref object of OpenApiRestCall_599368
proc url_UpdateChannel_600170(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_600169(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600171 = path.getOrDefault("channelName")
  valid_600171 = validateParameter(valid_600171, JString, required = true,
                                 default = nil)
  if valid_600171 != nil:
    section.add "channelName", valid_600171
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
  var valid_600174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Content-Sha256", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Algorithm")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Algorithm", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Signature")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Signature", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-SignedHeaders", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Credential")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Credential", valid_600178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_UpdateChannel_600168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_UpdateChannel_600168; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_600182 = newJObject()
  var body_600183 = newJObject()
  add(path_600182, "channelName", newJString(channelName))
  if body != nil:
    body_600183 = body
  result = call_600181.call(path_600182, nil, nil, nil, body_600183)

var updateChannel* = Call_UpdateChannel_600168(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_600169,
    base: "/", url: url_UpdateChannel_600170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_600152 = ref object of OpenApiRestCall_599368
proc url_DescribeChannel_600154(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_600153(path: JsonNode; query: JsonNode;
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
  var valid_600155 = path.getOrDefault("channelName")
  valid_600155 = validateParameter(valid_600155, JString, required = true,
                                 default = nil)
  if valid_600155 != nil:
    section.add "channelName", valid_600155
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_600156 = query.getOrDefault("includeStatistics")
  valid_600156 = validateParameter(valid_600156, JBool, required = false, default = nil)
  if valid_600156 != nil:
    section.add "includeStatistics", valid_600156
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
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600164: Call_DescribeChannel_600152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_600164.validator(path, query, header, formData, body)
  let scheme = call_600164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600164.url(scheme.get, call_600164.host, call_600164.base,
                         call_600164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600164, url, valid)

proc call*(call_600165: Call_DescribeChannel_600152; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  var path_600166 = newJObject()
  var query_600167 = newJObject()
  add(path_600166, "channelName", newJString(channelName))
  add(query_600167, "includeStatistics", newJBool(includeStatistics))
  result = call_600165.call(path_600166, query_600167, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_600152(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_600153,
    base: "/", url: url_DescribeChannel_600154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_600184 = ref object of OpenApiRestCall_599368
proc url_DeleteChannel_600186(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_600185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600187 = path.getOrDefault("channelName")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = nil)
  if valid_600187 != nil:
    section.add "channelName", valid_600187
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
  var valid_600188 = header.getOrDefault("X-Amz-Date")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Date", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Security-Token")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Security-Token", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600195: Call_DeleteChannel_600184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_600195.validator(path, query, header, formData, body)
  let scheme = call_600195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600195.url(scheme.get, call_600195.host, call_600195.base,
                         call_600195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600195, url, valid)

proc call*(call_600196: Call_DeleteChannel_600184; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_600197 = newJObject()
  add(path_600197, "channelName", newJString(channelName))
  result = call_600196.call(path_600197, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_600184(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_600185,
    base: "/", url: url_DeleteChannel_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_600212 = ref object of OpenApiRestCall_599368
proc url_UpdateDataset_600214(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataset_600213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600215 = path.getOrDefault("datasetName")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "datasetName", valid_600215
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
  var valid_600216 = header.getOrDefault("X-Amz-Date")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Date", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Security-Token")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Security-Token", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Content-Sha256", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Algorithm")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Algorithm", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Signature")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Signature", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-SignedHeaders", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Credential")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Credential", valid_600222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600224: Call_UpdateDataset_600212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_600224.validator(path, query, header, formData, body)
  let scheme = call_600224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600224.url(scheme.get, call_600224.host, call_600224.base,
                         call_600224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600224, url, valid)

proc call*(call_600225: Call_UpdateDataset_600212; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_600226 = newJObject()
  var body_600227 = newJObject()
  add(path_600226, "datasetName", newJString(datasetName))
  if body != nil:
    body_600227 = body
  result = call_600225.call(path_600226, nil, nil, nil, body_600227)

var updateDataset* = Call_UpdateDataset_600212(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_600213,
    base: "/", url: url_UpdateDataset_600214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_600198 = ref object of OpenApiRestCall_599368
proc url_DescribeDataset_600200(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_600199(path: JsonNode; query: JsonNode;
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
  var valid_600201 = path.getOrDefault("datasetName")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = nil)
  if valid_600201 != nil:
    section.add "datasetName", valid_600201
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Content-Sha256", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Algorithm")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Algorithm", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Signature")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Signature", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-SignedHeaders", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Credential")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Credential", valid_600208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_DescribeDataset_600198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_DescribeDataset_600198; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_600211 = newJObject()
  add(path_600211, "datasetName", newJString(datasetName))
  result = call_600210.call(path_600211, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_600198(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_600199,
    base: "/", url: url_DescribeDataset_600200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_600228 = ref object of OpenApiRestCall_599368
proc url_DeleteDataset_600230(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_600229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600231 = path.getOrDefault("datasetName")
  valid_600231 = validateParameter(valid_600231, JString, required = true,
                                 default = nil)
  if valid_600231 != nil:
    section.add "datasetName", valid_600231
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
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Content-Sha256", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Algorithm")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Algorithm", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Signature")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Signature", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-SignedHeaders", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Credential")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Credential", valid_600238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600239: Call_DeleteDataset_600228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_600239.validator(path, query, header, formData, body)
  let scheme = call_600239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600239.url(scheme.get, call_600239.host, call_600239.base,
                         call_600239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600239, url, valid)

proc call*(call_600240: Call_DeleteDataset_600228; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_600241 = newJObject()
  add(path_600241, "datasetName", newJString(datasetName))
  result = call_600240.call(path_600241, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_600228(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_600229,
    base: "/", url: url_DeleteDataset_600230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_600258 = ref object of OpenApiRestCall_599368
proc url_UpdateDatastore_600260(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatastore_600259(path: JsonNode; query: JsonNode;
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
  var valid_600261 = path.getOrDefault("datastoreName")
  valid_600261 = validateParameter(valid_600261, JString, required = true,
                                 default = nil)
  if valid_600261 != nil:
    section.add "datastoreName", valid_600261
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
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Content-Sha256", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Algorithm")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Algorithm", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Signature")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Signature", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-SignedHeaders", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Credential")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Credential", valid_600268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600270: Call_UpdateDatastore_600258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_600270.validator(path, query, header, formData, body)
  let scheme = call_600270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600270.url(scheme.get, call_600270.host, call_600270.base,
                         call_600270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600270, url, valid)

proc call*(call_600271: Call_UpdateDatastore_600258; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_600272 = newJObject()
  var body_600273 = newJObject()
  add(path_600272, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_600273 = body
  result = call_600271.call(path_600272, nil, nil, nil, body_600273)

var updateDatastore* = Call_UpdateDatastore_600258(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_600259,
    base: "/", url: url_UpdateDatastore_600260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_600242 = ref object of OpenApiRestCall_599368
proc url_DescribeDatastore_600244(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDatastore_600243(path: JsonNode; query: JsonNode;
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
  var valid_600245 = path.getOrDefault("datastoreName")
  valid_600245 = validateParameter(valid_600245, JString, required = true,
                                 default = nil)
  if valid_600245 != nil:
    section.add "datastoreName", valid_600245
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_600246 = query.getOrDefault("includeStatistics")
  valid_600246 = validateParameter(valid_600246, JBool, required = false, default = nil)
  if valid_600246 != nil:
    section.add "includeStatistics", valid_600246
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Content-Sha256", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Algorithm")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Algorithm", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Signature")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Signature", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-SignedHeaders", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Credential")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Credential", valid_600253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600254: Call_DescribeDatastore_600242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_600254.validator(path, query, header, formData, body)
  let scheme = call_600254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600254.url(scheme.get, call_600254.host, call_600254.base,
                         call_600254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600254, url, valid)

proc call*(call_600255: Call_DescribeDatastore_600242; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  var path_600256 = newJObject()
  var query_600257 = newJObject()
  add(query_600257, "includeStatistics", newJBool(includeStatistics))
  add(path_600256, "datastoreName", newJString(datastoreName))
  result = call_600255.call(path_600256, query_600257, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_600242(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_600243,
    base: "/", url: url_DescribeDatastore_600244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_600274 = ref object of OpenApiRestCall_599368
proc url_DeleteDatastore_600276(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatastore_600275(path: JsonNode; query: JsonNode;
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
  var valid_600277 = path.getOrDefault("datastoreName")
  valid_600277 = validateParameter(valid_600277, JString, required = true,
                                 default = nil)
  if valid_600277 != nil:
    section.add "datastoreName", valid_600277
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
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600285: Call_DeleteDatastore_600274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_DeleteDatastore_600274; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_600287 = newJObject()
  add(path_600287, "datastoreName", newJString(datastoreName))
  result = call_600286.call(path_600287, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_600274(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_600275,
    base: "/", url: url_DeleteDatastore_600276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_600302 = ref object of OpenApiRestCall_599368
proc url_UpdatePipeline_600304(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_600303(path: JsonNode; query: JsonNode;
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
  var valid_600305 = path.getOrDefault("pipelineName")
  valid_600305 = validateParameter(valid_600305, JString, required = true,
                                 default = nil)
  if valid_600305 != nil:
    section.add "pipelineName", valid_600305
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
  var valid_600306 = header.getOrDefault("X-Amz-Date")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Date", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Security-Token")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Security-Token", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Content-Sha256", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Algorithm")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Algorithm", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Signature")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Signature", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-SignedHeaders", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Credential")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Credential", valid_600312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600314: Call_UpdatePipeline_600302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_600314.validator(path, query, header, formData, body)
  let scheme = call_600314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600314.url(scheme.get, call_600314.host, call_600314.base,
                         call_600314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600314, url, valid)

proc call*(call_600315: Call_UpdatePipeline_600302; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_600316 = newJObject()
  var body_600317 = newJObject()
  add(path_600316, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_600317 = body
  result = call_600315.call(path_600316, nil, nil, nil, body_600317)

var updatePipeline* = Call_UpdatePipeline_600302(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_600303,
    base: "/", url: url_UpdatePipeline_600304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_600288 = ref object of OpenApiRestCall_599368
proc url_DescribePipeline_600290(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePipeline_600289(path: JsonNode; query: JsonNode;
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
  var valid_600291 = path.getOrDefault("pipelineName")
  valid_600291 = validateParameter(valid_600291, JString, required = true,
                                 default = nil)
  if valid_600291 != nil:
    section.add "pipelineName", valid_600291
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Content-Sha256", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Algorithm")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Algorithm", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Signature")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Signature", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-SignedHeaders", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Credential")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Credential", valid_600298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600299: Call_DescribePipeline_600288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_600299.validator(path, query, header, formData, body)
  let scheme = call_600299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600299.url(scheme.get, call_600299.host, call_600299.base,
                         call_600299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600299, url, valid)

proc call*(call_600300: Call_DescribePipeline_600288; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_600301 = newJObject()
  add(path_600301, "pipelineName", newJString(pipelineName))
  result = call_600300.call(path_600301, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_600288(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_600289,
    base: "/", url: url_DescribePipeline_600290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_600318 = ref object of OpenApiRestCall_599368
proc url_DeletePipeline_600320(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_600319(path: JsonNode; query: JsonNode;
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
  var valid_600321 = path.getOrDefault("pipelineName")
  valid_600321 = validateParameter(valid_600321, JString, required = true,
                                 default = nil)
  if valid_600321 != nil:
    section.add "pipelineName", valid_600321
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Content-Sha256", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Algorithm")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Algorithm", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Signature")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Signature", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-SignedHeaders", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Credential")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Credential", valid_600328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600329: Call_DeletePipeline_600318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_600329.validator(path, query, header, formData, body)
  let scheme = call_600329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600329.url(scheme.get, call_600329.host, call_600329.base,
                         call_600329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600329, url, valid)

proc call*(call_600330: Call_DeletePipeline_600318; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_600331 = newJObject()
  add(path_600331, "pipelineName", newJString(pipelineName))
  result = call_600330.call(path_600331, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_600318(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_600319,
    base: "/", url: url_DeletePipeline_600320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_600344 = ref object of OpenApiRestCall_599368
proc url_PutLoggingOptions_600346(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_600345(path: JsonNode; query: JsonNode;
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
  var valid_600347 = header.getOrDefault("X-Amz-Date")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Date", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Security-Token")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Security-Token", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Content-Sha256", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Algorithm")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Algorithm", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Signature")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Signature", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-SignedHeaders", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Credential")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Credential", valid_600353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600355: Call_PutLoggingOptions_600344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_600355.validator(path, query, header, formData, body)
  let scheme = call_600355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600355.url(scheme.get, call_600355.host, call_600355.base,
                         call_600355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600355, url, valid)

proc call*(call_600356: Call_PutLoggingOptions_600344; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_600357 = newJObject()
  if body != nil:
    body_600357 = body
  result = call_600356.call(nil, nil, nil, nil, body_600357)

var putLoggingOptions* = Call_PutLoggingOptions_600344(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_600345, base: "/",
    url: url_PutLoggingOptions_600346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_600332 = ref object of OpenApiRestCall_599368
proc url_DescribeLoggingOptions_600334(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_600333(path: JsonNode; query: JsonNode;
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
  var valid_600335 = header.getOrDefault("X-Amz-Date")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Date", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Security-Token")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Security-Token", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Content-Sha256", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Algorithm")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Algorithm", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Signature")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Signature", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-SignedHeaders", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Credential")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Credential", valid_600341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600342: Call_DescribeLoggingOptions_600332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_600342.validator(path, query, header, formData, body)
  let scheme = call_600342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600342.url(scheme.get, call_600342.host, call_600342.base,
                         call_600342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600342, url, valid)

proc call*(call_600343: Call_DescribeLoggingOptions_600332): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_600343.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_600332(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_600333, base: "/",
    url: url_DescribeLoggingOptions_600334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_600358 = ref object of OpenApiRestCall_599368
proc url_ListDatasetContents_600360(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasetContents_600359(path: JsonNode; query: JsonNode;
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
  var valid_600361 = path.getOrDefault("datasetName")
  valid_600361 = validateParameter(valid_600361, JString, required = true,
                                 default = nil)
  if valid_600361 != nil:
    section.add "datasetName", valid_600361
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
  var valid_600362 = query.getOrDefault("scheduledOnOrAfter")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "scheduledOnOrAfter", valid_600362
  var valid_600363 = query.getOrDefault("scheduledBefore")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "scheduledBefore", valid_600363
  var valid_600364 = query.getOrDefault("maxResults")
  valid_600364 = validateParameter(valid_600364, JInt, required = false, default = nil)
  if valid_600364 != nil:
    section.add "maxResults", valid_600364
  var valid_600365 = query.getOrDefault("nextToken")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "nextToken", valid_600365
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
  var valid_600366 = header.getOrDefault("X-Amz-Date")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Date", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Security-Token")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Security-Token", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Content-Sha256", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Algorithm")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Algorithm", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Signature")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Signature", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-SignedHeaders", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Credential")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Credential", valid_600372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600373: Call_ListDatasetContents_600358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_ListDatasetContents_600358; datasetName: string;
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
  var path_600375 = newJObject()
  var query_600376 = newJObject()
  add(query_600376, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(query_600376, "scheduledBefore", newJString(scheduledBefore))
  add(query_600376, "maxResults", newJInt(maxResults))
  add(query_600376, "nextToken", newJString(nextToken))
  add(path_600375, "datasetName", newJString(datasetName))
  result = call_600374.call(path_600375, query_600376, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_600358(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_600359, base: "/",
    url: url_ListDatasetContents_600360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600391 = ref object of OpenApiRestCall_599368
proc url_TagResource_600393(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600394 = query.getOrDefault("resourceArn")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "resourceArn", valid_600394
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
  var valid_600395 = header.getOrDefault("X-Amz-Date")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Date", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Security-Token")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Security-Token", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Content-Sha256", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Algorithm")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Algorithm", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Signature")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Signature", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-SignedHeaders", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Credential")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Credential", valid_600401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600403: Call_TagResource_600391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_600403.validator(path, query, header, formData, body)
  let scheme = call_600403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600403.url(scheme.get, call_600403.host, call_600403.base,
                         call_600403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600403, url, valid)

proc call*(call_600404: Call_TagResource_600391; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  ##   body: JObject (required)
  var query_600405 = newJObject()
  var body_600406 = newJObject()
  add(query_600405, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_600406 = body
  result = call_600404.call(nil, query_600405, nil, nil, body_600406)

var tagResource* = Call_TagResource_600391(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_600392,
                                        base: "/", url: url_TagResource_600393,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600377 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600379(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600378(path: JsonNode; query: JsonNode;
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
  var valid_600380 = query.getOrDefault("resourceArn")
  valid_600380 = validateParameter(valid_600380, JString, required = true,
                                 default = nil)
  if valid_600380 != nil:
    section.add "resourceArn", valid_600380
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
  var valid_600381 = header.getOrDefault("X-Amz-Date")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Date", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Security-Token")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Security-Token", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Content-Sha256", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Algorithm")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Algorithm", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Signature")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Signature", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-SignedHeaders", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Credential")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Credential", valid_600387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600388: Call_ListTagsForResource_600377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_600388.validator(path, query, header, formData, body)
  let scheme = call_600388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600388.url(scheme.get, call_600388.host, call_600388.base,
                         call_600388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600388, url, valid)

proc call*(call_600389: Call_ListTagsForResource_600377; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_600390 = newJObject()
  add(query_600390, "resourceArn", newJString(resourceArn))
  result = call_600389.call(nil, query_600390, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600377(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_600378, base: "/",
    url: url_ListTagsForResource_600379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_600407 = ref object of OpenApiRestCall_599368
proc url_RunPipelineActivity_600409(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RunPipelineActivity_600408(path: JsonNode; query: JsonNode;
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
  var valid_600410 = header.getOrDefault("X-Amz-Date")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Date", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Security-Token")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Security-Token", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Content-Sha256", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Algorithm")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Algorithm", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Signature")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Signature", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-SignedHeaders", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Credential")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Credential", valid_600416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600418: Call_RunPipelineActivity_600407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_600418.validator(path, query, header, formData, body)
  let scheme = call_600418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600418.url(scheme.get, call_600418.host, call_600418.base,
                         call_600418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600418, url, valid)

proc call*(call_600419: Call_RunPipelineActivity_600407; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_600420 = newJObject()
  if body != nil:
    body_600420 = body
  result = call_600419.call(nil, nil, nil, nil, body_600420)

var runPipelineActivity* = Call_RunPipelineActivity_600407(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_600408, base: "/",
    url: url_RunPipelineActivity_600409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_600421 = ref object of OpenApiRestCall_599368
proc url_SampleChannelData_600423(protocol: Scheme; host: string; base: string;
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

proc validate_SampleChannelData_600422(path: JsonNode; query: JsonNode;
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
  var valid_600424 = path.getOrDefault("channelName")
  valid_600424 = validateParameter(valid_600424, JString, required = true,
                                 default = nil)
  if valid_600424 != nil:
    section.add "channelName", valid_600424
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_600425 = query.getOrDefault("endTime")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "endTime", valid_600425
  var valid_600426 = query.getOrDefault("maxMessages")
  valid_600426 = validateParameter(valid_600426, JInt, required = false, default = nil)
  if valid_600426 != nil:
    section.add "maxMessages", valid_600426
  var valid_600427 = query.getOrDefault("startTime")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "startTime", valid_600427
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
  var valid_600428 = header.getOrDefault("X-Amz-Date")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Date", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Security-Token")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Security-Token", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600435: Call_SampleChannelData_600421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_600435.validator(path, query, header, formData, body)
  let scheme = call_600435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600435.url(scheme.get, call_600435.host, call_600435.base,
                         call_600435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600435, url, valid)

proc call*(call_600436: Call_SampleChannelData_600421; channelName: string;
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
  var path_600437 = newJObject()
  var query_600438 = newJObject()
  add(query_600438, "endTime", newJString(endTime))
  add(query_600438, "maxMessages", newJInt(maxMessages))
  add(path_600437, "channelName", newJString(channelName))
  add(query_600438, "startTime", newJString(startTime))
  result = call_600436.call(path_600437, query_600438, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_600421(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_600422, base: "/",
    url: url_SampleChannelData_600423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_600439 = ref object of OpenApiRestCall_599368
proc url_StartPipelineReprocessing_600441(protocol: Scheme; host: string;
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

proc validate_StartPipelineReprocessing_600440(path: JsonNode; query: JsonNode;
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
  var valid_600442 = path.getOrDefault("pipelineName")
  valid_600442 = validateParameter(valid_600442, JString, required = true,
                                 default = nil)
  if valid_600442 != nil:
    section.add "pipelineName", valid_600442
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
  var valid_600443 = header.getOrDefault("X-Amz-Date")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Date", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Security-Token")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Security-Token", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600451: Call_StartPipelineReprocessing_600439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_600451.validator(path, query, header, formData, body)
  let scheme = call_600451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600451.url(scheme.get, call_600451.host, call_600451.base,
                         call_600451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600451, url, valid)

proc call*(call_600452: Call_StartPipelineReprocessing_600439;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_600453 = newJObject()
  var body_600454 = newJObject()
  add(path_600453, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_600454 = body
  result = call_600452.call(path_600453, nil, nil, nil, body_600454)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_600439(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_600440, base: "/",
    url: url_StartPipelineReprocessing_600441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600455 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600457(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600456(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600458 = query.getOrDefault("resourceArn")
  valid_600458 = validateParameter(valid_600458, JString, required = true,
                                 default = nil)
  if valid_600458 != nil:
    section.add "resourceArn", valid_600458
  var valid_600459 = query.getOrDefault("tagKeys")
  valid_600459 = validateParameter(valid_600459, JArray, required = true, default = nil)
  if valid_600459 != nil:
    section.add "tagKeys", valid_600459
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
  var valid_600460 = header.getOrDefault("X-Amz-Date")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Date", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Security-Token")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Security-Token", valid_600461
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
  if body != nil:
    result.add "body", body

proc call*(call_600467: Call_UntagResource_600455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_600467.validator(path, query, header, formData, body)
  let scheme = call_600467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600467.url(scheme.get, call_600467.host, call_600467.base,
                         call_600467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600467, url, valid)

proc call*(call_600468: Call_UntagResource_600455; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var query_600469 = newJObject()
  add(query_600469, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_600469.add "tagKeys", tagKeys
  result = call_600468.call(nil, query_600469, nil, nil, nil)

var untagResource* = Call_UntagResource_600455(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_600456,
    base: "/", url: url_UntagResource_600457, schemes: {Scheme.Https, Scheme.Http})
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
