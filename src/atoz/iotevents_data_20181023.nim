
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_BatchPutMessage_592703 = ref object of OpenApiRestCall_592364
proc url_BatchPutMessage_592705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchPutMessage_592704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_BatchPutMessage_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_BatchPutMessage_592703; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var batchPutMessage* = Call_BatchPutMessage_592703(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "data.iotevents.amazonaws.com",
    route: "/inputs/messages", validator: validate_BatchPutMessage_592704,
    base: "/", url: url_BatchPutMessage_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateDetector_592958 = ref object of OpenApiRestCall_592364
proc url_BatchUpdateDetector_592960(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchUpdateDetector_592959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_BatchUpdateDetector_592958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_BatchUpdateDetector_592958; body: JsonNode): Recallable =
  ## batchUpdateDetector
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var batchUpdateDetector* = Call_BatchUpdateDetector_592958(
    name: "batchUpdateDetector", meth: HttpMethod.HttpPost,
    host: "data.iotevents.amazonaws.com", route: "/detectors",
    validator: validate_BatchUpdateDetector_592959, base: "/",
    url: url_BatchUpdateDetector_592960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_592972 = ref object of OpenApiRestCall_592364
proc url_DescribeDetector_592974(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetector_592973(path: JsonNode; query: JsonNode;
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
  var valid_592989 = path.getOrDefault("detectorModelName")
  valid_592989 = validateParameter(valid_592989, JString, required = true,
                                 default = nil)
  if valid_592989 != nil:
    section.add "detectorModelName", valid_592989
  result.add "path", section
  ## parameters in `query` object:
  ##   keyValue: JString
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  section = newJObject()
  var valid_592990 = query.getOrDefault("keyValue")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "keyValue", valid_592990
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
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592998: Call_DescribeDetector_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified detector (instance).
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_DescribeDetector_592972; detectorModelName: string;
          keyValue: string = ""): Recallable =
  ## describeDetector
  ## Returns information about the specified detector (instance).
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  ##   keyValue: string
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  var path_593000 = newJObject()
  var query_593001 = newJObject()
  add(path_593000, "detectorModelName", newJString(detectorModelName))
  add(query_593001, "keyValue", newJString(keyValue))
  result = call_592999.call(path_593000, query_593001, nil, nil, nil)

var describeDetector* = Call_DescribeDetector_592972(name: "describeDetector",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}/keyValues/",
    validator: validate_DescribeDetector_592973, base: "/",
    url: url_DescribeDetector_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_593003 = ref object of OpenApiRestCall_592364
proc url_ListDetectors_593005(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectors_593004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593006 = path.getOrDefault("detectorModelName")
  valid_593006 = validateParameter(valid_593006, JString, required = true,
                                 default = nil)
  if valid_593006 != nil:
    section.add "detectorModelName", valid_593006
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   stateName: JString
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_593007 = query.getOrDefault("nextToken")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "nextToken", valid_593007
  var valid_593008 = query.getOrDefault("stateName")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "stateName", valid_593008
  var valid_593009 = query.getOrDefault("maxResults")
  valid_593009 = validateParameter(valid_593009, JInt, required = false, default = nil)
  if valid_593009 != nil:
    section.add "maxResults", valid_593009
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
  var valid_593010 = header.getOrDefault("X-Amz-Signature")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Signature", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Content-Sha256", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Date")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Date", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Credential")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Credential", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Security-Token")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Security-Token", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Algorithm")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Algorithm", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-SignedHeaders", valid_593016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_ListDetectors_593003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectors (the instances of a detector model).
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_ListDetectors_593003; detectorModelName: string;
          nextToken: string = ""; stateName: string = ""; maxResults: int = 0): Recallable =
  ## listDetectors
  ## Lists detectors (the instances of a detector model).
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) are listed.
  ##   stateName: string
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var path_593019 = newJObject()
  var query_593020 = newJObject()
  add(query_593020, "nextToken", newJString(nextToken))
  add(path_593019, "detectorModelName", newJString(detectorModelName))
  add(query_593020, "stateName", newJString(stateName))
  add(query_593020, "maxResults", newJInt(maxResults))
  result = call_593018.call(path_593019, query_593020, nil, nil, nil)

var listDetectors* = Call_ListDetectors_593003(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}", validator: validate_ListDetectors_593004,
    base: "/", url: url_ListDetectors_593005, schemes: {Scheme.Https, Scheme.Http})
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
