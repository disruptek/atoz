
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_BatchPutMessage_601727 = ref object of OpenApiRestCall_601389
proc url_BatchPutMessage_601729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchPutMessage_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_BatchPutMessage_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends messages to a channel.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_BatchPutMessage_601727; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends messages to a channel.
  ##   body: JObject (required)
  var body_601943 = newJObject()
  if body != nil:
    body_601943 = body
  result = call_601942.call(nil, nil, nil, nil, body_601943)

var batchPutMessage* = Call_BatchPutMessage_601727(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/messages/batch", validator: validate_BatchPutMessage_601728, base: "/",
    url: url_BatchPutMessage_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelPipelineReprocessing_601982 = ref object of OpenApiRestCall_601389
proc url_CancelPipelineReprocessing_601984(protocol: Scheme; host: string;
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

proc validate_CancelPipelineReprocessing_601983(path: JsonNode; query: JsonNode;
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
  var valid_601999 = path.getOrDefault("reprocessingId")
  valid_601999 = validateParameter(valid_601999, JString, required = true,
                                 default = nil)
  if valid_601999 != nil:
    section.add "reprocessingId", valid_601999
  var valid_602000 = path.getOrDefault("pipelineName")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "pipelineName", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CancelPipelineReprocessing_601982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the reprocessing of data through the pipeline.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelPipelineReprocessing_601982;
          reprocessingId: string; pipelineName: string): Recallable =
  ## cancelPipelineReprocessing
  ## Cancels the reprocessing of data through the pipeline.
  ##   reprocessingId: string (required)
  ##                 : The ID of the reprocessing task (returned by "StartPipelineReprocessing").
  ##   pipelineName: string (required)
  ##               : The name of pipeline for which data reprocessing is canceled.
  var path_602010 = newJObject()
  add(path_602010, "reprocessingId", newJString(reprocessingId))
  add(path_602010, "pipelineName", newJString(pipelineName))
  result = call_602009.call(path_602010, nil, nil, nil, nil)

var cancelPipelineReprocessing* = Call_CancelPipelineReprocessing_601982(
    name: "cancelPipelineReprocessing", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing/{reprocessingId}",
    validator: validate_CancelPipelineReprocessing_601983, base: "/",
    url: url_CancelPipelineReprocessing_601984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_602027 = ref object of OpenApiRestCall_601389
proc url_CreateChannel_602029(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_602028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateChannel_602027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateChannel_602027; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a channel. A channel collects data from an MQTT topic and archives the raw, unprocessed messages before publishing the data to a pipeline.
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createChannel* = Call_CreateChannel_602027(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_602028, base: "/",
    url: url_CreateChannel_602029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_602012 = ref object of OpenApiRestCall_601389
proc url_ListChannels_602014(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_602013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602015 = query.getOrDefault("nextToken")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "nextToken", valid_602015
  var valid_602016 = query.getOrDefault("maxResults")
  valid_602016 = validateParameter(valid_602016, JInt, required = false, default = nil)
  if valid_602016 != nil:
    section.add "maxResults", valid_602016
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
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Content-Sha256", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Date")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Date", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Credential")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Credential", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Security-Token")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Security-Token", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Algorithm")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Algorithm", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_ListChannels_602012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of channels.
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_ListChannels_602012; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listChannels
  ## Retrieves a list of channels.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_602026 = newJObject()
  add(query_602026, "nextToken", newJString(nextToken))
  add(query_602026, "maxResults", newJInt(maxResults))
  result = call_602025.call(nil, query_602026, nil, nil, nil)

var listChannels* = Call_ListChannels_602012(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_602013, base: "/",
    url: url_ListChannels_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_602056 = ref object of OpenApiRestCall_601389
proc url_CreateDataset_602058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataset_602057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Signature")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Signature", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Date")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Date", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Credential")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Credential", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Security-Token")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Security-Token", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Algorithm")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Algorithm", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-SignedHeaders", valid_602065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602067: Call_CreateDataset_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ## 
  let valid = call_602067.validator(path, query, header, formData, body)
  let scheme = call_602067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602067.url(scheme.get, call_602067.host, call_602067.base,
                         call_602067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602067, url, valid)

proc call*(call_602068: Call_CreateDataset_602056; body: JsonNode): Recallable =
  ## createDataset
  ## Creates a data set. A data set stores data retrieved from a data store by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application). This operation creates the skeleton of a data set. The data set can be populated manually by calling "CreateDatasetContent" or automatically according to a "trigger" you specify.
  ##   body: JObject (required)
  var body_602069 = newJObject()
  if body != nil:
    body_602069 = body
  result = call_602068.call(nil, nil, nil, nil, body_602069)

var createDataset* = Call_CreateDataset_602056(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_CreateDataset_602057, base: "/",
    url: url_CreateDataset_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_602041 = ref object of OpenApiRestCall_601389
proc url_ListDatasets_602043(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasets_602042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602044 = query.getOrDefault("nextToken")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "nextToken", valid_602044
  var valid_602045 = query.getOrDefault("maxResults")
  valid_602045 = validateParameter(valid_602045, JInt, required = false, default = nil)
  if valid_602045 != nil:
    section.add "maxResults", valid_602045
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
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_ListDatasets_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about data sets.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_ListDatasets_602041; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatasets
  ## Retrieves information about data sets.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_602055 = newJObject()
  add(query_602055, "nextToken", newJString(nextToken))
  add(query_602055, "maxResults", newJInt(maxResults))
  result = call_602054.call(nil, query_602055, nil, nil, nil)

var listDatasets* = Call_ListDatasets_602041(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets", validator: validate_ListDatasets_602042, base: "/",
    url: url_ListDatasets_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetContent_602086 = ref object of OpenApiRestCall_601389
proc url_CreateDatasetContent_602088(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatasetContent_602087(path: JsonNode; query: JsonNode;
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
  var valid_602089 = path.getOrDefault("datasetName")
  valid_602089 = validateParameter(valid_602089, JString, required = true,
                                 default = nil)
  if valid_602089 != nil:
    section.add "datasetName", valid_602089
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
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602097: Call_CreateDatasetContent_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ## 
  let valid = call_602097.validator(path, query, header, formData, body)
  let scheme = call_602097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602097.url(scheme.get, call_602097.host, call_602097.base,
                         call_602097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602097, url, valid)

proc call*(call_602098: Call_CreateDatasetContent_602086; datasetName: string): Recallable =
  ## createDatasetContent
  ## Creates the content of a data set by applying a "queryAction" (a SQL query) or a "containerAction" (executing a containerized application).
  ##   datasetName: string (required)
  ##              : The name of the data set.
  var path_602099 = newJObject()
  add(path_602099, "datasetName", newJString(datasetName))
  result = call_602098.call(path_602099, nil, nil, nil, nil)

var createDatasetContent* = Call_CreateDatasetContent_602086(
    name: "createDatasetContent", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_CreateDatasetContent_602087, base: "/",
    url: url_CreateDatasetContent_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatasetContent_602070 = ref object of OpenApiRestCall_601389
proc url_GetDatasetContent_602072(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatasetContent_602071(path: JsonNode; query: JsonNode;
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
  var valid_602073 = path.getOrDefault("datasetName")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = nil)
  if valid_602073 != nil:
    section.add "datasetName", valid_602073
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_602074 = query.getOrDefault("versionId")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "versionId", valid_602074
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
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602082: Call_GetDatasetContent_602070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contents of a data set as pre-signed URIs.
  ## 
  let valid = call_602082.validator(path, query, header, formData, body)
  let scheme = call_602082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602082.url(scheme.get, call_602082.host, call_602082.base,
                         call_602082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602082, url, valid)

proc call*(call_602083: Call_GetDatasetContent_602070; datasetName: string;
          versionId: string = ""): Recallable =
  ## getDatasetContent
  ## Retrieves the contents of a data set as pre-signed URIs.
  ##   versionId: string
  ##            : The version of the data set whose contents are retrieved. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to retrieve the contents of the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose contents are retrieved.
  var path_602084 = newJObject()
  var query_602085 = newJObject()
  add(query_602085, "versionId", newJString(versionId))
  add(path_602084, "datasetName", newJString(datasetName))
  result = call_602083.call(path_602084, query_602085, nil, nil, nil)

var getDatasetContent* = Call_GetDatasetContent_602070(name: "getDatasetContent",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}/content",
    validator: validate_GetDatasetContent_602071, base: "/",
    url: url_GetDatasetContent_602072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetContent_602100 = ref object of OpenApiRestCall_601389
proc url_DeleteDatasetContent_602102(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatasetContent_602101(path: JsonNode; query: JsonNode;
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
  var valid_602103 = path.getOrDefault("datasetName")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = nil)
  if valid_602103 != nil:
    section.add "datasetName", valid_602103
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  section = newJObject()
  var valid_602104 = query.getOrDefault("versionId")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "versionId", valid_602104
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
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602112: Call_DeleteDatasetContent_602100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of the specified data set.
  ## 
  let valid = call_602112.validator(path, query, header, formData, body)
  let scheme = call_602112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602112.url(scheme.get, call_602112.host, call_602112.base,
                         call_602112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602112, url, valid)

proc call*(call_602113: Call_DeleteDatasetContent_602100; datasetName: string;
          versionId: string = ""): Recallable =
  ## deleteDatasetContent
  ## Deletes the content of the specified data set.
  ##   versionId: string
  ##            : The version of the data set whose content is deleted. You can also use the strings "$LATEST" or "$LATEST_SUCCEEDED" to delete the latest or latest successfully completed data set. If not specified, "$LATEST_SUCCEEDED" is the default.
  ##   datasetName: string (required)
  ##              : The name of the data set whose content is deleted.
  var path_602114 = newJObject()
  var query_602115 = newJObject()
  add(query_602115, "versionId", newJString(versionId))
  add(path_602114, "datasetName", newJString(datasetName))
  result = call_602113.call(path_602114, query_602115, nil, nil, nil)

var deleteDatasetContent* = Call_DeleteDatasetContent_602100(
    name: "deleteDatasetContent", meth: HttpMethod.HttpDelete,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/content",
    validator: validate_DeleteDatasetContent_602101, base: "/",
    url: url_DeleteDatasetContent_602102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatastore_602131 = ref object of OpenApiRestCall_601389
proc url_CreateDatastore_602133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatastore_602132(path: JsonNode; query: JsonNode;
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
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Content-Sha256", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Date")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Date", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Credential")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Credential", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Security-Token")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Security-Token", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Algorithm")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Algorithm", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-SignedHeaders", valid_602140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_CreateDatastore_602131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data store, which is a repository for messages.
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_CreateDatastore_602131; body: JsonNode): Recallable =
  ## createDatastore
  ## Creates a data store, which is a repository for messages.
  ##   body: JObject (required)
  var body_602144 = newJObject()
  if body != nil:
    body_602144 = body
  result = call_602143.call(nil, nil, nil, nil, body_602144)

var createDatastore* = Call_CreateDatastore_602131(name: "createDatastore",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_CreateDatastore_602132, base: "/",
    url: url_CreateDatastore_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatastores_602116 = ref object of OpenApiRestCall_601389
proc url_ListDatastores_602118(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatastores_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = query.getOrDefault("nextToken")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "nextToken", valid_602119
  var valid_602120 = query.getOrDefault("maxResults")
  valid_602120 = validateParameter(valid_602120, JInt, required = false, default = nil)
  if valid_602120 != nil:
    section.add "maxResults", valid_602120
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
  var valid_602121 = header.getOrDefault("X-Amz-Signature")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Signature", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Content-Sha256", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Date")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Date", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_ListDatastores_602116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of data stores.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_ListDatastores_602116; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDatastores
  ## Retrieves a list of data stores.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_602130 = newJObject()
  add(query_602130, "nextToken", newJString(nextToken))
  add(query_602130, "maxResults", newJInt(maxResults))
  result = call_602129.call(nil, query_602130, nil, nil, nil)

var listDatastores* = Call_ListDatastores_602116(name: "listDatastores",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores", validator: validate_ListDatastores_602117, base: "/",
    url: url_ListDatastores_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_602160 = ref object of OpenApiRestCall_601389
proc url_CreatePipeline_602162(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_602161(path: JsonNode; query: JsonNode;
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
  var valid_602163 = header.getOrDefault("X-Amz-Signature")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Signature", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Date")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Date", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Credential")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Credential", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Security-Token")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Security-Token", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Algorithm")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Algorithm", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-SignedHeaders", valid_602169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602171: Call_CreatePipeline_602160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_602171.validator(path, query, header, formData, body)
  let scheme = call_602171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602171.url(scheme.get, call_602171.host, call_602171.base,
                         call_602171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602171, url, valid)

proc call*(call_602172: Call_CreatePipeline_602160; body: JsonNode): Recallable =
  ## createPipeline
  ## Creates a pipeline. A pipeline consumes messages from a channel and allows you to process the messages before storing them in a data store. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   body: JObject (required)
  var body_602173 = newJObject()
  if body != nil:
    body_602173 = body
  result = call_602172.call(nil, nil, nil, nil, body_602173)

var createPipeline* = Call_CreatePipeline_602160(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_CreatePipeline_602161, base: "/",
    url: url_CreatePipeline_602162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_602145 = ref object of OpenApiRestCall_601389
proc url_ListPipelines_602147(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_602146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602148 = query.getOrDefault("nextToken")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "nextToken", valid_602148
  var valid_602149 = query.getOrDefault("maxResults")
  valid_602149 = validateParameter(valid_602149, JInt, required = false, default = nil)
  if valid_602149 != nil:
    section.add "maxResults", valid_602149
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
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602157: Call_ListPipelines_602145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of pipelines.
  ## 
  let valid = call_602157.validator(path, query, header, formData, body)
  let scheme = call_602157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602157.url(scheme.get, call_602157.host, call_602157.base,
                         call_602157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602157, url, valid)

proc call*(call_602158: Call_ListPipelines_602145; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listPipelines
  ## Retrieves a list of pipelines.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : <p>The maximum number of results to return in this request.</p> <p>The default value is 100.</p>
  var query_602159 = newJObject()
  add(query_602159, "nextToken", newJString(nextToken))
  add(query_602159, "maxResults", newJInt(maxResults))
  result = call_602158.call(nil, query_602159, nil, nil, nil)

var listPipelines* = Call_ListPipelines_602145(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines", validator: validate_ListPipelines_602146, base: "/",
    url: url_ListPipelines_602147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_602190 = ref object of OpenApiRestCall_601389
proc url_UpdateChannel_602192(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_602191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602193 = path.getOrDefault("channelName")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "channelName", valid_602193
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
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_UpdateChannel_602190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a channel.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_UpdateChannel_602190; channelName: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates the settings of a channel.
  ##   channelName: string (required)
  ##              : The name of the channel to be updated.
  ##   body: JObject (required)
  var path_602204 = newJObject()
  var body_602205 = newJObject()
  add(path_602204, "channelName", newJString(channelName))
  if body != nil:
    body_602205 = body
  result = call_602203.call(path_602204, nil, nil, nil, body_602205)

var updateChannel* = Call_UpdateChannel_602190(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_UpdateChannel_602191,
    base: "/", url: url_UpdateChannel_602192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_602174 = ref object of OpenApiRestCall_601389
proc url_DescribeChannel_602176(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_602175(path: JsonNode; query: JsonNode;
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
  var valid_602177 = path.getOrDefault("channelName")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "channelName", valid_602177
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  section = newJObject()
  var valid_602178 = query.getOrDefault("includeStatistics")
  valid_602178 = validateParameter(valid_602178, JBool, required = false, default = nil)
  if valid_602178 != nil:
    section.add "includeStatistics", valid_602178
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
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Date")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Date", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Credential")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Credential", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Security-Token")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Security-Token", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Algorithm")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Algorithm", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-SignedHeaders", valid_602185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_DescribeChannel_602174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a channel.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_DescribeChannel_602174; channelName: string;
          includeStatistics: bool = false): Recallable =
  ## describeChannel
  ## Retrieves information about a channel.
  ##   channelName: string (required)
  ##              : The name of the channel whose information is retrieved.
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the channel is included in the response. This feature cannot be used with a channel whose S3 storage is customer-managed.
  var path_602188 = newJObject()
  var query_602189 = newJObject()
  add(path_602188, "channelName", newJString(channelName))
  add(query_602189, "includeStatistics", newJBool(includeStatistics))
  result = call_602187.call(path_602188, query_602189, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_602174(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DescribeChannel_602175,
    base: "/", url: url_DescribeChannel_602176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_602206 = ref object of OpenApiRestCall_601389
proc url_DeleteChannel_602208(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_602207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602209 = path.getOrDefault("channelName")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "channelName", valid_602209
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
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602217: Call_DeleteChannel_602206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified channel.
  ## 
  let valid = call_602217.validator(path, query, header, formData, body)
  let scheme = call_602217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602217.url(scheme.get, call_602217.host, call_602217.base,
                         call_602217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602217, url, valid)

proc call*(call_602218: Call_DeleteChannel_602206; channelName: string): Recallable =
  ## deleteChannel
  ## Deletes the specified channel.
  ##   channelName: string (required)
  ##              : The name of the channel to delete.
  var path_602219 = newJObject()
  add(path_602219, "channelName", newJString(channelName))
  result = call_602218.call(path_602219, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_602206(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}", validator: validate_DeleteChannel_602207,
    base: "/", url: url_DeleteChannel_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataset_602234 = ref object of OpenApiRestCall_601389
proc url_UpdateDataset_602236(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataset_602235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602237 = path.getOrDefault("datasetName")
  valid_602237 = validateParameter(valid_602237, JString, required = true,
                                 default = nil)
  if valid_602237 != nil:
    section.add "datasetName", valid_602237
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
  var valid_602238 = header.getOrDefault("X-Amz-Signature")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Signature", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Content-Sha256", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Date")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Date", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Credential")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Credential", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Security-Token")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Security-Token", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Algorithm")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Algorithm", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-SignedHeaders", valid_602244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602246: Call_UpdateDataset_602234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data set.
  ## 
  let valid = call_602246.validator(path, query, header, formData, body)
  let scheme = call_602246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602246.url(scheme.get, call_602246.host, call_602246.base,
                         call_602246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602246, url, valid)

proc call*(call_602247: Call_UpdateDataset_602234; datasetName: string;
          body: JsonNode): Recallable =
  ## updateDataset
  ## Updates the settings of a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set to update.
  ##   body: JObject (required)
  var path_602248 = newJObject()
  var body_602249 = newJObject()
  add(path_602248, "datasetName", newJString(datasetName))
  if body != nil:
    body_602249 = body
  result = call_602247.call(path_602248, nil, nil, nil, body_602249)

var updateDataset* = Call_UpdateDataset_602234(name: "updateDataset",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_UpdateDataset_602235,
    base: "/", url: url_UpdateDataset_602236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_602220 = ref object of OpenApiRestCall_601389
proc url_DescribeDataset_602222(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_602221(path: JsonNode; query: JsonNode;
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
  var valid_602223 = path.getOrDefault("datasetName")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "datasetName", valid_602223
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
  var valid_602224 = header.getOrDefault("X-Amz-Signature")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Signature", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Content-Sha256", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Date")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Date", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Credential")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Credential", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Security-Token")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Security-Token", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Algorithm")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Algorithm", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-SignedHeaders", valid_602230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_DescribeDataset_602220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data set.
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_DescribeDataset_602220; datasetName: string): Recallable =
  ## describeDataset
  ## Retrieves information about a data set.
  ##   datasetName: string (required)
  ##              : The name of the data set whose information is retrieved.
  var path_602233 = newJObject()
  add(path_602233, "datasetName", newJString(datasetName))
  result = call_602232.call(path_602233, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_602220(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DescribeDataset_602221,
    base: "/", url: url_DescribeDataset_602222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_602250 = ref object of OpenApiRestCall_601389
proc url_DeleteDataset_602252(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_602251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602253 = path.getOrDefault("datasetName")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "datasetName", valid_602253
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
  var valid_602254 = header.getOrDefault("X-Amz-Signature")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Signature", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Content-Sha256", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Date")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Date", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Credential")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Credential", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Security-Token")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Security-Token", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Algorithm")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Algorithm", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-SignedHeaders", valid_602260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602261: Call_DeleteDataset_602250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ## 
  let valid = call_602261.validator(path, query, header, formData, body)
  let scheme = call_602261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602261.url(scheme.get, call_602261.host, call_602261.base,
                         call_602261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602261, url, valid)

proc call*(call_602262: Call_DeleteDataset_602250; datasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specified data set.</p> <p>You do not have to delete the content of the data set before you perform this operation.</p>
  ##   datasetName: string (required)
  ##              : The name of the data set to delete.
  var path_602263 = newJObject()
  add(path_602263, "datasetName", newJString(datasetName))
  result = call_602262.call(path_602263, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_602250(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datasets/{datasetName}", validator: validate_DeleteDataset_602251,
    base: "/", url: url_DeleteDataset_602252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatastore_602280 = ref object of OpenApiRestCall_601389
proc url_UpdateDatastore_602282(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatastore_602281(path: JsonNode; query: JsonNode;
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
  var valid_602283 = path.getOrDefault("datastoreName")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "datastoreName", valid_602283
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
  var valid_602284 = header.getOrDefault("X-Amz-Signature")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Signature", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Content-Sha256", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Date")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Date", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Algorithm")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Algorithm", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602292: Call_UpdateDatastore_602280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a data store.
  ## 
  let valid = call_602292.validator(path, query, header, formData, body)
  let scheme = call_602292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602292.url(scheme.get, call_602292.host, call_602292.base,
                         call_602292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602292, url, valid)

proc call*(call_602293: Call_UpdateDatastore_602280; datastoreName: string;
          body: JsonNode): Recallable =
  ## updateDatastore
  ## Updates the settings of a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to be updated.
  ##   body: JObject (required)
  var path_602294 = newJObject()
  var body_602295 = newJObject()
  add(path_602294, "datastoreName", newJString(datastoreName))
  if body != nil:
    body_602295 = body
  result = call_602293.call(path_602294, nil, nil, nil, body_602295)

var updateDatastore* = Call_UpdateDatastore_602280(name: "updateDatastore",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_UpdateDatastore_602281,
    base: "/", url: url_UpdateDatastore_602282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatastore_602264 = ref object of OpenApiRestCall_601389
proc url_DescribeDatastore_602266(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDatastore_602265(path: JsonNode; query: JsonNode;
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
  var valid_602267 = path.getOrDefault("datastoreName")
  valid_602267 = validateParameter(valid_602267, JString, required = true,
                                 default = nil)
  if valid_602267 != nil:
    section.add "datastoreName", valid_602267
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatistics: JBool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  section = newJObject()
  var valid_602268 = query.getOrDefault("includeStatistics")
  valid_602268 = validateParameter(valid_602268, JBool, required = false, default = nil)
  if valid_602268 != nil:
    section.add "includeStatistics", valid_602268
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
  var valid_602269 = header.getOrDefault("X-Amz-Signature")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Signature", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Content-Sha256", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Date")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Date", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Credential")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Credential", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Security-Token")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Security-Token", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Algorithm")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Algorithm", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-SignedHeaders", valid_602275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_DescribeDatastore_602264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a data store.
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_DescribeDatastore_602264; datastoreName: string;
          includeStatistics: bool = false): Recallable =
  ## describeDatastore
  ## Retrieves information about a data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store
  ##   includeStatistics: bool
  ##                    : If true, additional statistical information about the data store is included in the response. This feature cannot be used with a data store whose S3 storage is customer-managed.
  var path_602278 = newJObject()
  var query_602279 = newJObject()
  add(path_602278, "datastoreName", newJString(datastoreName))
  add(query_602279, "includeStatistics", newJBool(includeStatistics))
  result = call_602277.call(path_602278, query_602279, nil, nil, nil)

var describeDatastore* = Call_DescribeDatastore_602264(name: "describeDatastore",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DescribeDatastore_602265,
    base: "/", url: url_DescribeDatastore_602266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatastore_602296 = ref object of OpenApiRestCall_601389
proc url_DeleteDatastore_602298(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatastore_602297(path: JsonNode; query: JsonNode;
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
  var valid_602299 = path.getOrDefault("datastoreName")
  valid_602299 = validateParameter(valid_602299, JString, required = true,
                                 default = nil)
  if valid_602299 != nil:
    section.add "datastoreName", valid_602299
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
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602307: Call_DeleteDatastore_602296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified data store.
  ## 
  let valid = call_602307.validator(path, query, header, formData, body)
  let scheme = call_602307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602307.url(scheme.get, call_602307.host, call_602307.base,
                         call_602307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602307, url, valid)

proc call*(call_602308: Call_DeleteDatastore_602296; datastoreName: string): Recallable =
  ## deleteDatastore
  ## Deletes the specified data store.
  ##   datastoreName: string (required)
  ##                : The name of the data store to delete.
  var path_602309 = newJObject()
  add(path_602309, "datastoreName", newJString(datastoreName))
  result = call_602308.call(path_602309, nil, nil, nil, nil)

var deleteDatastore* = Call_DeleteDatastore_602296(name: "deleteDatastore",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/datastores/{datastoreName}", validator: validate_DeleteDatastore_602297,
    base: "/", url: url_DeleteDatastore_602298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_602324 = ref object of OpenApiRestCall_601389
proc url_UpdatePipeline_602326(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_602325(path: JsonNode; query: JsonNode;
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
  var valid_602327 = path.getOrDefault("pipelineName")
  valid_602327 = validateParameter(valid_602327, JString, required = true,
                                 default = nil)
  if valid_602327 != nil:
    section.add "pipelineName", valid_602327
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
  var valid_602328 = header.getOrDefault("X-Amz-Signature")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Signature", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Content-Sha256", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Date")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Date", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Credential")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Credential", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Security-Token")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Security-Token", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602336: Call_UpdatePipeline_602324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ## 
  let valid = call_602336.validator(path, query, header, formData, body)
  let scheme = call_602336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602336.url(scheme.get, call_602336.host, call_602336.base,
                         call_602336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602336, url, valid)

proc call*(call_602337: Call_UpdatePipeline_602324; pipelineName: string;
          body: JsonNode): Recallable =
  ## updatePipeline
  ## Updates the settings of a pipeline. You must specify both a <code>channel</code> and a <code>datastore</code> activity and, optionally, as many as 23 additional activities in the <code>pipelineActivities</code> array.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to update.
  ##   body: JObject (required)
  var path_602338 = newJObject()
  var body_602339 = newJObject()
  add(path_602338, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_602339 = body
  result = call_602337.call(path_602338, nil, nil, nil, body_602339)

var updatePipeline* = Call_UpdatePipeline_602324(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_UpdatePipeline_602325,
    base: "/", url: url_UpdatePipeline_602326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePipeline_602310 = ref object of OpenApiRestCall_601389
proc url_DescribePipeline_602312(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePipeline_602311(path: JsonNode; query: JsonNode;
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
  var valid_602313 = path.getOrDefault("pipelineName")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = nil)
  if valid_602313 != nil:
    section.add "pipelineName", valid_602313
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
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Security-Token")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Security-Token", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Algorithm")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Algorithm", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_DescribePipeline_602310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a pipeline.
  ## 
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602321, url, valid)

proc call*(call_602322: Call_DescribePipeline_602310; pipelineName: string): Recallable =
  ## describePipeline
  ## Retrieves information about a pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline whose information is retrieved.
  var path_602323 = newJObject()
  add(path_602323, "pipelineName", newJString(pipelineName))
  result = call_602322.call(path_602323, nil, nil, nil, nil)

var describePipeline* = Call_DescribePipeline_602310(name: "describePipeline",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DescribePipeline_602311,
    base: "/", url: url_DescribePipeline_602312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_602340 = ref object of OpenApiRestCall_601389
proc url_DeletePipeline_602342(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_602341(path: JsonNode; query: JsonNode;
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
  var valid_602343 = path.getOrDefault("pipelineName")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = nil)
  if valid_602343 != nil:
    section.add "pipelineName", valid_602343
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
  var valid_602344 = header.getOrDefault("X-Amz-Signature")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Signature", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Content-Sha256", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Date")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Date", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Credential")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Credential", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Security-Token")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Security-Token", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Algorithm")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Algorithm", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-SignedHeaders", valid_602350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602351: Call_DeletePipeline_602340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified pipeline.
  ## 
  let valid = call_602351.validator(path, query, header, formData, body)
  let scheme = call_602351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602351.url(scheme.get, call_602351.host, call_602351.base,
                         call_602351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602351, url, valid)

proc call*(call_602352: Call_DeletePipeline_602340; pipelineName: string): Recallable =
  ## deletePipeline
  ## Deletes the specified pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline to delete.
  var path_602353 = newJObject()
  add(path_602353, "pipelineName", newJString(pipelineName))
  result = call_602352.call(path_602353, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_602340(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}", validator: validate_DeletePipeline_602341,
    base: "/", url: url_DeletePipeline_602342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_602366 = ref object of OpenApiRestCall_601389
proc url_PutLoggingOptions_602368(protocol: Scheme; host: string; base: string;
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

proc validate_PutLoggingOptions_602367(path: JsonNode; query: JsonNode;
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
  var valid_602369 = header.getOrDefault("X-Amz-Signature")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Signature", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Content-Sha256", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Date")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Date", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Credential")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Credential", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Security-Token")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Security-Token", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Algorithm")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Algorithm", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-SignedHeaders", valid_602375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602377: Call_PutLoggingOptions_602366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ## 
  let valid = call_602377.validator(path, query, header, formData, body)
  let scheme = call_602377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602377.url(scheme.get, call_602377.host, call_602377.base,
                         call_602377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602377, url, valid)

proc call*(call_602378: Call_PutLoggingOptions_602366; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Analytics logging options.</p> <p>Note that if you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the roleArn field (for example, to correct an invalid policy) it takes up to 5 minutes for that change to take effect. </p>
  ##   body: JObject (required)
  var body_602379 = newJObject()
  if body != nil:
    body_602379 = body
  result = call_602378.call(nil, nil, nil, nil, body_602379)

var putLoggingOptions* = Call_PutLoggingOptions_602366(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_602367, base: "/",
    url: url_PutLoggingOptions_602368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_602354 = ref object of OpenApiRestCall_601389
proc url_DescribeLoggingOptions_602356(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLoggingOptions_602355(path: JsonNode; query: JsonNode;
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
  var valid_602357 = header.getOrDefault("X-Amz-Signature")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Signature", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Content-Sha256", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Date")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Date", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Credential")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Credential", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Security-Token")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Security-Token", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-SignedHeaders", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602364: Call_DescribeLoggingOptions_602354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  ## 
  let valid = call_602364.validator(path, query, header, formData, body)
  let scheme = call_602364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602364.url(scheme.get, call_602364.host, call_602364.base,
                         call_602364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602364, url, valid)

proc call*(call_602365: Call_DescribeLoggingOptions_602354): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Analytics logging options.
  result = call_602365.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_602354(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_602355, base: "/",
    url: url_DescribeLoggingOptions_602356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetContents_602380 = ref object of OpenApiRestCall_601389
proc url_ListDatasetContents_602382(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasetContents_602381(path: JsonNode; query: JsonNode;
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
  var valid_602383 = path.getOrDefault("datasetName")
  valid_602383 = validateParameter(valid_602383, JString, required = true,
                                 default = nil)
  if valid_602383 != nil:
    section.add "datasetName", valid_602383
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
  var valid_602384 = query.getOrDefault("nextToken")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "nextToken", valid_602384
  var valid_602385 = query.getOrDefault("scheduledOnOrAfter")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "scheduledOnOrAfter", valid_602385
  var valid_602386 = query.getOrDefault("scheduledBefore")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "scheduledBefore", valid_602386
  var valid_602387 = query.getOrDefault("maxResults")
  valid_602387 = validateParameter(valid_602387, JInt, required = false, default = nil)
  if valid_602387 != nil:
    section.add "maxResults", valid_602387
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
  var valid_602388 = header.getOrDefault("X-Amz-Signature")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Signature", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Content-Sha256", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Date")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Date", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Credential")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Credential", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Security-Token")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Security-Token", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Algorithm")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Algorithm", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-SignedHeaders", valid_602394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602395: Call_ListDatasetContents_602380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about data set contents that have been created.
  ## 
  let valid = call_602395.validator(path, query, header, formData, body)
  let scheme = call_602395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602395.url(scheme.get, call_602395.host, call_602395.base,
                         call_602395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602395, url, valid)

proc call*(call_602396: Call_ListDatasetContents_602380; datasetName: string;
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
  var path_602397 = newJObject()
  var query_602398 = newJObject()
  add(query_602398, "nextToken", newJString(nextToken))
  add(query_602398, "scheduledOnOrAfter", newJString(scheduledOnOrAfter))
  add(path_602397, "datasetName", newJString(datasetName))
  add(query_602398, "scheduledBefore", newJString(scheduledBefore))
  add(query_602398, "maxResults", newJInt(maxResults))
  result = call_602396.call(path_602397, query_602398, nil, nil, nil)

var listDatasetContents* = Call_ListDatasetContents_602380(
    name: "listDatasetContents", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/datasets/{datasetName}/contents",
    validator: validate_ListDatasetContents_602381, base: "/",
    url: url_ListDatasetContents_602382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602413 = ref object of OpenApiRestCall_601389
proc url_TagResource_602415(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602416 = query.getOrDefault("resourceArn")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = nil)
  if valid_602416 != nil:
    section.add "resourceArn", valid_602416
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
  var valid_602417 = header.getOrDefault("X-Amz-Signature")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Signature", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Content-Sha256", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Date")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Date", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Credential")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Credential", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Security-Token")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Security-Token", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Algorithm")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Algorithm", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-SignedHeaders", valid_602423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602425: Call_TagResource_602413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ## 
  let valid = call_602425.validator(path, query, header, formData, body)
  let scheme = call_602425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602425.url(scheme.get, call_602425.host, call_602425.base,
                         call_602425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602425, url, valid)

proc call*(call_602426: Call_TagResource_602413; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to modify.
  var query_602427 = newJObject()
  var body_602428 = newJObject()
  if body != nil:
    body_602428 = body
  add(query_602427, "resourceArn", newJString(resourceArn))
  result = call_602426.call(nil, query_602427, nil, nil, body_602428)

var tagResource* = Call_TagResource_602413(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotanalytics.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_602414,
                                        base: "/", url: url_TagResource_602415,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602399 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602401(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602400(path: JsonNode; query: JsonNode;
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
  var valid_602402 = query.getOrDefault("resourceArn")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = nil)
  if valid_602402 != nil:
    section.add "resourceArn", valid_602402
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
  var valid_602403 = header.getOrDefault("X-Amz-Signature")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Signature", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Content-Sha256", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Date")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Date", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Credential")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Credential", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Security-Token")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Security-Token", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Algorithm")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Algorithm", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-SignedHeaders", valid_602409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602410: Call_ListTagsForResource_602399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) which you have assigned to the resource.
  ## 
  let valid = call_602410.validator(path, query, header, formData, body)
  let scheme = call_602410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602410.url(scheme.get, call_602410.host, call_602410.base,
                         call_602410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602410, url, valid)

proc call*(call_602411: Call_ListTagsForResource_602399; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var query_602412 = newJObject()
  add(query_602412, "resourceArn", newJString(resourceArn))
  result = call_602411.call(nil, query_602412, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602399(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotanalytics.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_602400, base: "/",
    url: url_ListTagsForResource_602401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunPipelineActivity_602429 = ref object of OpenApiRestCall_601389
proc url_RunPipelineActivity_602431(protocol: Scheme; host: string; base: string;
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

proc validate_RunPipelineActivity_602430(path: JsonNode; query: JsonNode;
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
  var valid_602432 = header.getOrDefault("X-Amz-Signature")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Signature", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Content-Sha256", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Date")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Date", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Credential")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Credential", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Security-Token")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Security-Token", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Algorithm")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Algorithm", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-SignedHeaders", valid_602438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602440: Call_RunPipelineActivity_602429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulates the results of running a pipeline activity on a message payload.
  ## 
  let valid = call_602440.validator(path, query, header, formData, body)
  let scheme = call_602440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602440.url(scheme.get, call_602440.host, call_602440.base,
                         call_602440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602440, url, valid)

proc call*(call_602441: Call_RunPipelineActivity_602429; body: JsonNode): Recallable =
  ## runPipelineActivity
  ## Simulates the results of running a pipeline activity on a message payload.
  ##   body: JObject (required)
  var body_602442 = newJObject()
  if body != nil:
    body_602442 = body
  result = call_602441.call(nil, nil, nil, nil, body_602442)

var runPipelineActivity* = Call_RunPipelineActivity_602429(
    name: "runPipelineActivity", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com", route: "/pipelineactivities/run",
    validator: validate_RunPipelineActivity_602430, base: "/",
    url: url_RunPipelineActivity_602431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SampleChannelData_602443 = ref object of OpenApiRestCall_601389
proc url_SampleChannelData_602445(protocol: Scheme; host: string; base: string;
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

proc validate_SampleChannelData_602444(path: JsonNode; query: JsonNode;
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
  var valid_602446 = path.getOrDefault("channelName")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "channelName", valid_602446
  result.add "path", section
  ## parameters in `query` object:
  ##   startTime: JString
  ##            : The start of the time window from which sample messages are retrieved.
  ##   maxMessages: JInt
  ##              : The number of sample messages to be retrieved. The limit is 10, the default is also 10.
  ##   endTime: JString
  ##          : The end of the time window from which sample messages are retrieved.
  section = newJObject()
  var valid_602447 = query.getOrDefault("startTime")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "startTime", valid_602447
  var valid_602448 = query.getOrDefault("maxMessages")
  valid_602448 = validateParameter(valid_602448, JInt, required = false, default = nil)
  if valid_602448 != nil:
    section.add "maxMessages", valid_602448
  var valid_602449 = query.getOrDefault("endTime")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "endTime", valid_602449
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
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Credential")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Credential", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Security-Token")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Security-Token", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-SignedHeaders", valid_602456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602457: Call_SampleChannelData_602443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a sample of messages from the specified channel ingested during the specified timeframe. Up to 10 messages can be retrieved.
  ## 
  let valid = call_602457.validator(path, query, header, formData, body)
  let scheme = call_602457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602457.url(scheme.get, call_602457.host, call_602457.base,
                         call_602457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602457, url, valid)

proc call*(call_602458: Call_SampleChannelData_602443; channelName: string;
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
  var path_602459 = newJObject()
  var query_602460 = newJObject()
  add(query_602460, "startTime", newJString(startTime))
  add(query_602460, "maxMessages", newJInt(maxMessages))
  add(path_602459, "channelName", newJString(channelName))
  add(query_602460, "endTime", newJString(endTime))
  result = call_602458.call(path_602459, query_602460, nil, nil, nil)

var sampleChannelData* = Call_SampleChannelData_602443(name: "sampleChannelData",
    meth: HttpMethod.HttpGet, host: "iotanalytics.amazonaws.com",
    route: "/channels/{channelName}/sample",
    validator: validate_SampleChannelData_602444, base: "/",
    url: url_SampleChannelData_602445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPipelineReprocessing_602461 = ref object of OpenApiRestCall_601389
proc url_StartPipelineReprocessing_602463(protocol: Scheme; host: string;
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

proc validate_StartPipelineReprocessing_602462(path: JsonNode; query: JsonNode;
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
  var valid_602464 = path.getOrDefault("pipelineName")
  valid_602464 = validateParameter(valid_602464, JString, required = true,
                                 default = nil)
  if valid_602464 != nil:
    section.add "pipelineName", valid_602464
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
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Content-Sha256", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Credential")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Credential", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Security-Token")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Security-Token", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-SignedHeaders", valid_602471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602473: Call_StartPipelineReprocessing_602461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the reprocessing of raw message data through the pipeline.
  ## 
  let valid = call_602473.validator(path, query, header, formData, body)
  let scheme = call_602473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602473.url(scheme.get, call_602473.host, call_602473.base,
                         call_602473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602473, url, valid)

proc call*(call_602474: Call_StartPipelineReprocessing_602461;
          pipelineName: string; body: JsonNode): Recallable =
  ## startPipelineReprocessing
  ## Starts the reprocessing of raw message data through the pipeline.
  ##   pipelineName: string (required)
  ##               : The name of the pipeline on which to start reprocessing.
  ##   body: JObject (required)
  var path_602475 = newJObject()
  var body_602476 = newJObject()
  add(path_602475, "pipelineName", newJString(pipelineName))
  if body != nil:
    body_602476 = body
  result = call_602474.call(path_602475, nil, nil, nil, body_602476)

var startPipelineReprocessing* = Call_StartPipelineReprocessing_602461(
    name: "startPipelineReprocessing", meth: HttpMethod.HttpPost,
    host: "iotanalytics.amazonaws.com",
    route: "/pipelines/{pipelineName}/reprocessing",
    validator: validate_StartPipelineReprocessing_602462, base: "/",
    url: url_StartPipelineReprocessing_602463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602477 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602479(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602480 = query.getOrDefault("tagKeys")
  valid_602480 = validateParameter(valid_602480, JArray, required = true, default = nil)
  if valid_602480 != nil:
    section.add "tagKeys", valid_602480
  var valid_602481 = query.getOrDefault("resourceArn")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = nil)
  if valid_602481 != nil:
    section.add "resourceArn", valid_602481
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
  var valid_602482 = header.getOrDefault("X-Amz-Signature")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Signature", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Content-Sha256", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Date")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Date", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Credential")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Credential", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Security-Token")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Security-Token", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Algorithm")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Algorithm", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-SignedHeaders", valid_602488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602489: Call_UntagResource_602477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_602489.validator(path, query, header, formData, body)
  let scheme = call_602489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602489.url(scheme.get, call_602489.host, call_602489.base,
                         call_602489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602489, url, valid)

proc call*(call_602490: Call_UntagResource_602477; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to remove.
  var query_602491 = newJObject()
  if tagKeys != nil:
    query_602491.add "tagKeys", tagKeys
  add(query_602491, "resourceArn", newJString(resourceArn))
  result = call_602490.call(nil, query_602491, nil, nil, nil)

var untagResource* = Call_UntagResource_602477(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotanalytics.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_602478,
    base: "/", url: url_UntagResource_602479, schemes: {Scheme.Https, Scheme.Http})
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
