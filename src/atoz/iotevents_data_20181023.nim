
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
  Call_BatchPutMessage_772933 = ref object of OpenApiRestCall_772597
proc url_BatchPutMessage_772935(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchPutMessage_772934(path: JsonNode; query: JsonNode;
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
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
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
  ## Sends a set of messages to the AWS IoT Events system. Each message payload is transformed into the input you specify (<code>"inputName"</code>) and ingested into any detectors that monitor that input. If multiple messages are sent, the order in which the messages are processed isn't guaranteed. To guarantee ordering, you must send messages one at a time and wait for a successful response.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var batchPutMessage* = Call_BatchPutMessage_772933(name: "batchPutMessage",
    meth: HttpMethod.HttpPost, host: "data.iotevents.amazonaws.com",
    route: "/inputs/messages", validator: validate_BatchPutMessage_772934,
    base: "/", url: url_BatchPutMessage_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateDetector_773188 = ref object of OpenApiRestCall_772597
proc url_BatchUpdateDetector_773190(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchUpdateDetector_773189(path: JsonNode; query: JsonNode;
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
  var valid_773191 = header.getOrDefault("X-Amz-Date")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Date", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Security-Token")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Security-Token", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Content-Sha256", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Algorithm")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Algorithm", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Signature")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Signature", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-SignedHeaders", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Credential")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Credential", valid_773197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_BatchUpdateDetector_773188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ## 
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_BatchUpdateDetector_773188; body: JsonNode): Recallable =
  ## batchUpdateDetector
  ## Updates the state, variable values, and timer settings of one or more detectors (instances) of a specified detector model.
  ##   body: JObject (required)
  var body_773201 = newJObject()
  if body != nil:
    body_773201 = body
  result = call_773200.call(nil, nil, nil, nil, body_773201)

var batchUpdateDetector* = Call_BatchUpdateDetector_773188(
    name: "batchUpdateDetector", meth: HttpMethod.HttpPost,
    host: "data.iotevents.amazonaws.com", route: "/detectors",
    validator: validate_BatchUpdateDetector_773189, base: "/",
    url: url_BatchUpdateDetector_773190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_773202 = ref object of OpenApiRestCall_772597
proc url_DescribeDetector_773204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetector_773203(path: JsonNode; query: JsonNode;
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
  var valid_773219 = path.getOrDefault("detectorModelName")
  valid_773219 = validateParameter(valid_773219, JString, required = true,
                                 default = nil)
  if valid_773219 != nil:
    section.add "detectorModelName", valid_773219
  result.add "path", section
  ## parameters in `query` object:
  ##   keyValue: JString
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  section = newJObject()
  var valid_773220 = query.getOrDefault("keyValue")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "keyValue", valid_773220
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
  var valid_773221 = header.getOrDefault("X-Amz-Date")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Date", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Security-Token")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Security-Token", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773228: Call_DescribeDetector_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified detector (instance).
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_DescribeDetector_773202; detectorModelName: string;
          keyValue: string = ""): Recallable =
  ## describeDetector
  ## Returns information about the specified detector (instance).
  ##   keyValue: string
  ##           : A filter used to limit results to detectors (instances) created because of the given key ID.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose detectors (instances) you want information about.
  var path_773230 = newJObject()
  var query_773231 = newJObject()
  add(query_773231, "keyValue", newJString(keyValue))
  add(path_773230, "detectorModelName", newJString(detectorModelName))
  result = call_773229.call(path_773230, query_773231, nil, nil, nil)

var describeDetector* = Call_DescribeDetector_773202(name: "describeDetector",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}/keyValues/",
    validator: validate_DescribeDetector_773203, base: "/",
    url: url_DescribeDetector_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_773233 = ref object of OpenApiRestCall_772597
proc url_ListDetectors_773235(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectors_773234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773236 = path.getOrDefault("detectorModelName")
  valid_773236 = validateParameter(valid_773236, JString, required = true,
                                 default = nil)
  if valid_773236 != nil:
    section.add "detectorModelName", valid_773236
  result.add "path", section
  ## parameters in `query` object:
  ##   stateName: JString
  ##            : A filter that limits results to those detectors (instances) in the given state.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_773237 = query.getOrDefault("stateName")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "stateName", valid_773237
  var valid_773238 = query.getOrDefault("maxResults")
  valid_773238 = validateParameter(valid_773238, JInt, required = false, default = nil)
  if valid_773238 != nil:
    section.add "maxResults", valid_773238
  var valid_773239 = query.getOrDefault("nextToken")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "nextToken", valid_773239
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
  var valid_773240 = header.getOrDefault("X-Amz-Date")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Date", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Security-Token")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Security-Token", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Content-Sha256", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Algorithm")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Algorithm", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Signature")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Signature", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-SignedHeaders", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Credential")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Credential", valid_773246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773247: Call_ListDetectors_773233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectors (the instances of a detector model).
  ## 
  let valid = call_773247.validator(path, query, header, formData, body)
  let scheme = call_773247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773247.url(scheme.get, call_773247.host, call_773247.base,
                         call_773247.route, valid.getOrDefault("path"))
  result = hook(call_773247, url, valid)

proc call*(call_773248: Call_ListDetectors_773233; detectorModelName: string;
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
  var path_773249 = newJObject()
  var query_773250 = newJObject()
  add(query_773250, "stateName", newJString(stateName))
  add(query_773250, "maxResults", newJInt(maxResults))
  add(query_773250, "nextToken", newJString(nextToken))
  add(path_773249, "detectorModelName", newJString(detectorModelName))
  result = call_773248.call(path_773249, query_773250, nil, nil, nil)

var listDetectors* = Call_ListDetectors_773233(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "data.iotevents.amazonaws.com",
    route: "/detectors/{detectorModelName}", validator: validate_ListDetectors_773234,
    base: "/", url: url_ListDetectors_773235, schemes: {Scheme.Https, Scheme.Http})
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
