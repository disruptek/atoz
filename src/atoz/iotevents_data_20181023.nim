
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_593774 = ref object of OpenApiRestCall_593437
proc url_BatchPutMessage_593776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchPutMessage_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Content-Sha256", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Algorithm")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Algorithm", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Signature")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Signature", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-SignedHeaders", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Credential")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Credential", valid_593894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_BatchPutMessage_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ## 
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593989: Call_BatchPutMessage_593774; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ##   body: JObject (required)
  var body_593990 = newJObject()
  if body != nil:
    body_593990 = body
  result = call_593989.call(nil, nil, nil, nil, body_593990)

var batchPutMessage* = Call_BatchPutMessage_593774(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "data.iotevents.amazonaws.com",
    route: "/inputs/messages", validator: validate_BatchPutMessage_593775,
    base: "/", url: url_BatchPutMessage_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateDetector_594029 = ref object of OpenApiRestCall_593437
proc url_BatchUpdateDetector_594031(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchUpdateDetector_594030(path: JsonNode; query: JsonNode;
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
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Security-Token")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Security-Token", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Content-Sha256", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Signature")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Signature", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-SignedHeaders", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Credential")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Credential", valid_594038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594040: Call_BatchUpdateDetector_594029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ## 
  let valid = call_594040.validator(path, query, header, formData, body)
  let scheme = call_594040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594040.url(scheme.get, call_594040.host, call_594040.base,
                         call_594040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594040, url, valid)

proc call*(call_594041: Call_BatchUpdateDetector_594029; body: JsonNode): Recallable =
  ## batchUpdateDetector
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ##   body: JObject (required)
  var body_594042 = newJObject()
  if body != nil:
    body_594042 = body
  result = call_594041.call(nil, nil, nil, nil, body_594042)

var batchUpdateDetector* = Call_BatchUpdateDetector_594029(
    name: "batchUpdateDetector", meth: HttpMethod.HttpPost,
    host: "data.iotevents.amazonaws.com", route: "/detectors",
    validator: validate_BatchUpdateDetector_594030, base: "/",
    url: url_BatchUpdateDetector_594031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_594043 = ref object of OpenApiRestCall_593437
proc url_DescribeDetector_594045(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DescribeDetector_594044(path: JsonNode; query: JsonNode;
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
  var valid_594060 = path.getOrDefault("detectorModelName")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = nil)
  if valid_594060 != nil:
    section.add "detectorModelName", valid_594060
  result.add "path", section
  ## parameters in `query` object:
  ##   keyValue: JString
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  section = newJObject()
  var valid_594061 = query.getOrDefault("keyValue")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "keyValue", valid_594061
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
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Security-Token")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Security-Token", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594069: Call_DescribeDetector_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified detector (instance).
  ## 
  let valid = call_594069.validator(path, query, header, formData, body)
  let scheme = call_594069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594069.url(scheme.get, call_594069.host, call_594069.base,
                         call_594069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594069, url, valid)

proc call*(call_594070: Call_DescribeDetector_594043; detectorModelName: string;
          keyValue: string = ""): Recallable =
  ## describeDetector
  ## Returns information about the specified detector (instance).
  ##   keyValue: string
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  var path_594071 = newJObject()
  var query_594072 = newJObject()
  add(query_594072, "keyValue", newJString(keyValue))
  add(path_594071, "detectorModelName", newJString(detectorModelName))
  result = call_594070.call(path_594071, query_594072, nil, nil, nil)

var describeDetector* = Call_DescribeDetector_594043(name: "describeDetector",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}/keyValues/",
    validator: validate_DescribeDetector_594044, base: "/",
    url: url_DescribeDetector_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_594074 = ref object of OpenApiRestCall_593437
proc url_ListDetectors_594076(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detectors/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDetectors_594075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594077 = path.getOrDefault("detectorModelName")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "detectorModelName", valid_594077
  result.add "path", section
  ## parameters in `query` object:
  ##   stateName: JString
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_594078 = query.getOrDefault("stateName")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "stateName", valid_594078
  var valid_594079 = query.getOrDefault("maxResults")
  valid_594079 = validateParameter(valid_594079, JInt, required = false, default = nil)
  if valid_594079 != nil:
    section.add "maxResults", valid_594079
  var valid_594080 = query.getOrDefault("nextToken")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "nextToken", valid_594080
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
  var valid_594081 = header.getOrDefault("X-Amz-Date")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Date", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Security-Token")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Security-Token", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Content-Sha256", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Algorithm")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Algorithm", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Signature")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Signature", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-SignedHeaders", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Credential")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Credential", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_ListDetectors_594074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectors (the instances of a detector model).
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_ListDetectors_594074; detectorModelName: string;
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
  var path_594090 = newJObject()
  var query_594091 = newJObject()
  add(query_594091, "stateName", newJString(stateName))
  add(query_594091, "maxResults", newJInt(maxResults))
  add(query_594091, "nextToken", newJString(nextToken))
  add(path_594090, "detectorModelName", newJString(detectorModelName))
  result = call_594089.call(path_594090, query_594091, nil, nil, nil)

var listDetectors* = Call_ListDetectors_594074(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}", validator: validate_ListDetectors_594075,
    base: "/", url: url_ListDetectors_594076, schemes: {Scheme.Https, Scheme.Http})
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
