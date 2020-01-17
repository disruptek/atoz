
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchPutMessage_605927 = ref object of OpenApiRestCall_605589
proc url_BatchPutMessage_605929(protocol: Scheme; host: string; base: string;
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

proc validate_BatchPutMessage_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Algorithm")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Algorithm", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-SignedHeaders", valid_606047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_BatchPutMessage_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ## 
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_BatchPutMessage_605927; body: JsonNode): Recallable =
  ## batchPutMessage
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ##   body: JObject (required)
  var body_606143 = newJObject()
  if body != nil:
    body_606143 = body
  result = call_606142.call(nil, nil, nil, nil, body_606143)

var batchPutMessage* = Call_BatchPutMessage_605927(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "data.iotevents.amazonaws.com",
    route: "/inputs/messages", validator: validate_BatchPutMessage_605928,
    base: "/", url: url_BatchPutMessage_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateDetector_606182 = ref object of OpenApiRestCall_605589
proc url_BatchUpdateDetector_606184(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateDetector_606183(path: JsonNode; query: JsonNode;
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
  var valid_606185 = header.getOrDefault("X-Amz-Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Signature", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Content-Sha256", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Date")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Date", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Credential")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Credential", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Security-Token")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Security-Token", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Algorithm")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Algorithm", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_BatchUpdateDetector_606182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_BatchUpdateDetector_606182; body: JsonNode): Recallable =
  ## batchUpdateDetector
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ##   body: JObject (required)
  var body_606195 = newJObject()
  if body != nil:
    body_606195 = body
  result = call_606194.call(nil, nil, nil, nil, body_606195)

var batchUpdateDetector* = Call_BatchUpdateDetector_606182(
    name: "batchUpdateDetector", meth: HttpMethod.HttpPost,
    host: "data.iotevents.amazonaws.com", route: "/detectors",
    validator: validate_BatchUpdateDetector_606183, base: "/",
    url: url_BatchUpdateDetector_606184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_606196 = ref object of OpenApiRestCall_605589
proc url_DescribeDetector_606198(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDetector_606197(path: JsonNode; query: JsonNode;
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
  var valid_606213 = path.getOrDefault("detectorModelName")
  valid_606213 = validateParameter(valid_606213, JString, required = true,
                                 default = nil)
  if valid_606213 != nil:
    section.add "detectorModelName", valid_606213
  result.add "path", section
  ## parameters in `query` object:
  ##   keyValue: JString
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  section = newJObject()
  var valid_606214 = query.getOrDefault("keyValue")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "keyValue", valid_606214
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
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606222: Call_DescribeDetector_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified detector (instance).
  ## 
  let valid = call_606222.validator(path, query, header, formData, body)
  let scheme = call_606222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606222.url(scheme.get, call_606222.host, call_606222.base,
                         call_606222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606222, url, valid)

proc call*(call_606223: Call_DescribeDetector_606196; detectorModelName: string;
          keyValue: string = ""): Recallable =
  ## describeDetector
  ## Returns information about the specified detector (instance).
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  ##   keyValue: string
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  var path_606224 = newJObject()
  var query_606225 = newJObject()
  add(path_606224, "detectorModelName", newJString(detectorModelName))
  add(query_606225, "keyValue", newJString(keyValue))
  result = call_606223.call(path_606224, query_606225, nil, nil, nil)

var describeDetector* = Call_DescribeDetector_606196(name: "describeDetector",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}/keyValues/",
    validator: validate_DescribeDetector_606197, base: "/",
    url: url_DescribeDetector_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_606227 = ref object of OpenApiRestCall_605589
proc url_ListDetectors_606229(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDetectors_606228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606230 = path.getOrDefault("detectorModelName")
  valid_606230 = validateParameter(valid_606230, JString, required = true,
                                 default = nil)
  if valid_606230 != nil:
    section.add "detectorModelName", valid_606230
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   stateName: JString
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_606231 = query.getOrDefault("nextToken")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "nextToken", valid_606231
  var valid_606232 = query.getOrDefault("stateName")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "stateName", valid_606232
  var valid_606233 = query.getOrDefault("maxResults")
  valid_606233 = validateParameter(valid_606233, JInt, required = false, default = nil)
  if valid_606233 != nil:
    section.add "maxResults", valid_606233
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
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_ListDetectors_606227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectors (the instances of a detector model).
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_ListDetectors_606227; detectorModelName: string;
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
  var path_606243 = newJObject()
  var query_606244 = newJObject()
  add(query_606244, "nextToken", newJString(nextToken))
  add(path_606243, "detectorModelName", newJString(detectorModelName))
  add(query_606244, "stateName", newJString(stateName))
  add(query_606244, "maxResults", newJInt(maxResults))
  result = call_606242.call(path_606243, query_606244, nil, nil, nil)

var listDetectors* = Call_ListDetectors_606227(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}", validator: validate_ListDetectors_606228,
    base: "/", url: url_ListDetectors_606229, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
