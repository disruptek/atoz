
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Events Data
## version: 2018-10-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS IoT Events monitors your equipment or device fleets for failures or changes in operation, and triggers actions when such events occur. AWS IoT Events Data API commands enable you to send inputs to detectors, list detectors, and view or update a detector's status.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotevents/
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "data.iotevents.ap-northeast-1.amazonaws.com", "ap-southeast-1": "data.iotevents.ap-southeast-1.amazonaws.com", "us-west-2": "data.iotevents.us-west-2.amazonaws.com", "eu-west-2": "data.iotevents.eu-west-2.amazonaws.com", "ap-northeast-3": "data.iotevents.ap-northeast-3.amazonaws.com", "eu-central-1": "data.iotevents.eu-central-1.amazonaws.com", "us-east-2": "data.iotevents.us-east-2.amazonaws.com", "us-east-1": "data.iotevents.us-east-1.amazonaws.com", "cn-northwest-1": "data.iotevents.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "data.iotevents.ap-south-1.amazonaws.com", "eu-north-1": "data.iotevents.eu-north-1.amazonaws.com", "ap-northeast-2": "data.iotevents.ap-northeast-2.amazonaws.com", "us-west-1": "data.iotevents.us-west-1.amazonaws.com", "us-gov-east-1": "data.iotevents.us-gov-east-1.amazonaws.com", "eu-west-3": "data.iotevents.eu-west-3.amazonaws.com", "cn-north-1": "data.iotevents.cn-north-1.amazonaws.com.cn", "sa-east-1": "data.iotevents.sa-east-1.amazonaws.com", "eu-west-1": "data.iotevents.eu-west-1.amazonaws.com", "us-gov-west-1": "data.iotevents.us-gov-west-1.amazonaws.com", "ap-southeast-2": "data.iotevents.ap-southeast-2.amazonaws.com", "ca-central-1": "data.iotevents.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "data.iotevents.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "data.iotevents.ap-southeast-1.amazonaws.com",
      "us-west-2": "data.iotevents.us-west-2.amazonaws.com",
      "eu-west-2": "data.iotevents.eu-west-2.amazonaws.com",
      "ap-northeast-3": "data.iotevents.ap-northeast-3.amazonaws.com",
      "eu-central-1": "data.iotevents.eu-central-1.amazonaws.com",
      "us-east-2": "data.iotevents.us-east-2.amazonaws.com",
      "us-east-1": "data.iotevents.us-east-1.amazonaws.com",
      "cn-northwest-1": "data.iotevents.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "data.iotevents.ap-south-1.amazonaws.com",
      "eu-north-1": "data.iotevents.eu-north-1.amazonaws.com",
      "ap-northeast-2": "data.iotevents.ap-northeast-2.amazonaws.com",
      "us-west-1": "data.iotevents.us-west-1.amazonaws.com",
      "us-gov-east-1": "data.iotevents.us-gov-east-1.amazonaws.com",
      "eu-west-3": "data.iotevents.eu-west-3.amazonaws.com",
      "cn-north-1": "data.iotevents.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "data.iotevents.sa-east-1.amazonaws.com",
      "eu-west-1": "data.iotevents.eu-west-1.amazonaws.com",
      "us-gov-west-1": "data.iotevents.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "data.iotevents.ap-southeast-2.amazonaws.com",
      "ca-central-1": "data.iotevents.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotevents-data"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_600768 = ref object of OpenApiRestCall_600426
proc url_BatchPutMessage_600770(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchPutMessage_600769(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_BatchPutMessage_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_BatchPutMessage_600768; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ##   body: JObject (required)
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var batchPutMessage* = Call_BatchPutMessage_600768(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "data.iotevents.amazonaws.com",
    route: "/inputs/messages", validator: validate_BatchPutMessage_600769,
    base: "/", url: url_BatchPutMessage_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateDetector_601023 = ref object of OpenApiRestCall_600426
proc url_BatchUpdateDetector_601025(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchUpdateDetector_601024(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
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
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Content-Sha256", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Algorithm")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Algorithm", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Signature")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Signature", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-SignedHeaders", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Credential")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Credential", valid_601032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_BatchUpdateDetector_601023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ## 
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_BatchUpdateDetector_601023; body: JsonNode): Recallable =
  ## batchUpdateDetector
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ##   body: JObject (required)
  var body_601036 = newJObject()
  if body != nil:
    body_601036 = body
  result = call_601035.call(nil, nil, nil, nil, body_601036)

var batchUpdateDetector* = Call_BatchUpdateDetector_601023(
    name: "batchUpdateDetector", meth: HttpMethod.HttpPost,
    host: "data.iotevents.amazonaws.com", route: "/detectors",
    validator: validate_BatchUpdateDetector_601024, base: "/",
    url: url_BatchUpdateDetector_601025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_601037 = ref object of OpenApiRestCall_600426
proc url_DescribeDetector_601039(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detectors/"),
               (kind: VariableSegment, value: "detectorModelName"),
               (kind: ConstantSegment, value: "/keyValues/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDetector_601038(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns information about the specified detector (instance).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_601054 = path.getOrDefault("detectorModelName")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = nil)
  if valid_601054 != nil:
    section.add "detectorModelName", valid_601054
  result.add "path", section
  ## parameters in `query` object:
  ##   keyValue: JString
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  section = newJObject()
  var valid_601055 = query.getOrDefault("keyValue")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "keyValue", valid_601055
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
  var valid_601056 = header.getOrDefault("X-Amz-Date")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Date", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Security-Token")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Security-Token", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601063: Call_DescribeDetector_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified detector (instance).
  ## 
  let valid = call_601063.validator(path, query, header, formData, body)
  let scheme = call_601063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601063.url(scheme.get, call_601063.host, call_601063.base,
                         call_601063.route, valid.getOrDefault("path"))
  result = hook(call_601063, url, valid)

proc call*(call_601064: Call_DescribeDetector_601037; detectorModelName: string;
          keyValue: string = ""): Recallable =
  ## describeDetector
  ## Returns information about the specified detector (instance).
  ##   keyValue: string
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  var path_601065 = newJObject()
  var query_601066 = newJObject()
  add(query_601066, "keyValue", newJString(keyValue))
  add(path_601065, "detectorModelName", newJString(detectorModelName))
  result = call_601064.call(path_601065, query_601066, nil, nil, nil)

var describeDetector* = Call_DescribeDetector_601037(name: "describeDetector",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}/keyValues/",
    validator: validate_DescribeDetector_601038, base: "/",
    url: url_DescribeDetector_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_601068 = ref object of OpenApiRestCall_600426
proc url_ListDetectors_601070(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detectors/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDetectors_601069(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists detectors (the instances of a detector model).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model whose detectors (instances) are listed.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_601071 = path.getOrDefault("detectorModelName")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "detectorModelName", valid_601071
  result.add "path", section
  ## parameters in `query` object:
  ##   stateName: JString
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_601072 = query.getOrDefault("stateName")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "stateName", valid_601072
  var valid_601073 = query.getOrDefault("maxResults")
  valid_601073 = validateParameter(valid_601073, JInt, required = false, default = nil)
  if valid_601073 != nil:
    section.add "maxResults", valid_601073
  var valid_601074 = query.getOrDefault("nextToken")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "nextToken", valid_601074
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
  var valid_601075 = header.getOrDefault("X-Amz-Date")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Date", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Security-Token")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Security-Token", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Content-Sha256", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Algorithm")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Algorithm", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Signature")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Signature", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-SignedHeaders", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Credential")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Credential", valid_601081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601082: Call_ListDetectors_601068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectors (the instances of a detector model).
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"))
  result = hook(call_601082, url, valid)

proc call*(call_601083: Call_ListDetectors_601068; detectorModelName: string;
          stateName: string = ""; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDetectors
  ## Lists detectors (the instances of a detector model).
  ##   stateName: string
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) are listed.
  var path_601084 = newJObject()
  var query_601085 = newJObject()
  add(query_601085, "stateName", newJString(stateName))
  add(query_601085, "maxResults", newJInt(maxResults))
  add(query_601085, "nextToken", newJString(nextToken))
  add(path_601084, "detectorModelName", newJString(detectorModelName))
  result = call_601083.call(path_601084, query_601085, nil, nil, nil)

var listDetectors* = Call_ListDetectors_601068(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}", validator: validate_ListDetectors_601069,
    base: "/", url: url_ListDetectors_601070, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
