
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Data Plane
## version: 2015-05-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS IoT</fullname> <p>AWS IoT-Data enables secure, bi-directional communication between Internet-connected things (such as sensors, actuators, embedded devices, or smart appliances) and the AWS cloud. It implements a broker for applications and things to publish messages over HTTP (Publish) and retrieve, update, and delete thing shadows. A thing shadow is a persistent representation of your things and their state in the AWS cloud.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iot/
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

  OpenApiRestCall_593424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593424): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "data.iot.ap-northeast-1.amazonaws.com", "ap-southeast-1": "data.iot.ap-southeast-1.amazonaws.com",
                           "us-west-2": "data.iot.us-west-2.amazonaws.com",
                           "eu-west-2": "data.iot.eu-west-2.amazonaws.com", "ap-northeast-3": "data.iot.ap-northeast-3.amazonaws.com", "eu-central-1": "data.iot.eu-central-1.amazonaws.com",
                           "us-east-2": "data.iot.us-east-2.amazonaws.com",
                           "us-east-1": "data.iot.us-east-1.amazonaws.com", "cn-northwest-1": "data.iot.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "data.iot.ap-south-1.amazonaws.com",
                           "eu-north-1": "data.iot.eu-north-1.amazonaws.com", "ap-northeast-2": "data.iot.ap-northeast-2.amazonaws.com",
                           "us-west-1": "data.iot.us-west-1.amazonaws.com", "us-gov-east-1": "data.iot.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "data.iot.eu-west-3.amazonaws.com", "cn-north-1": "data.iot.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "data.iot.sa-east-1.amazonaws.com",
                           "eu-west-1": "data.iot.eu-west-1.amazonaws.com", "us-gov-west-1": "data.iot.us-gov-west-1.amazonaws.com", "ap-southeast-2": "data.iot.ap-southeast-2.amazonaws.com", "ca-central-1": "data.iot.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "data.iot.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "data.iot.ap-southeast-1.amazonaws.com",
      "us-west-2": "data.iot.us-west-2.amazonaws.com",
      "eu-west-2": "data.iot.eu-west-2.amazonaws.com",
      "ap-northeast-3": "data.iot.ap-northeast-3.amazonaws.com",
      "eu-central-1": "data.iot.eu-central-1.amazonaws.com",
      "us-east-2": "data.iot.us-east-2.amazonaws.com",
      "us-east-1": "data.iot.us-east-1.amazonaws.com",
      "cn-northwest-1": "data.iot.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "data.iot.ap-south-1.amazonaws.com",
      "eu-north-1": "data.iot.eu-north-1.amazonaws.com",
      "ap-northeast-2": "data.iot.ap-northeast-2.amazonaws.com",
      "us-west-1": "data.iot.us-west-1.amazonaws.com",
      "us-gov-east-1": "data.iot.us-gov-east-1.amazonaws.com",
      "eu-west-3": "data.iot.eu-west-3.amazonaws.com",
      "cn-north-1": "data.iot.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "data.iot.sa-east-1.amazonaws.com",
      "eu-west-1": "data.iot.eu-west-1.amazonaws.com",
      "us-gov-west-1": "data.iot.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "data.iot.ap-southeast-2.amazonaws.com",
      "ca-central-1": "data.iot.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iot-data"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_UpdateThingShadow_594031 = ref object of OpenApiRestCall_593424
proc url_UpdateThingShadow_594033(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
               (kind: VariableSegment, value: "thingName"),
               (kind: ConstantSegment, value: "/shadow")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateThingShadow_594032(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_594034 = path.getOrDefault("thingName")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = nil)
  if valid_594034 != nil:
    section.add "thingName", valid_594034
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
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-SignedHeaders", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594043: Call_UpdateThingShadow_594031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_594043.validator(path, query, header, formData, body)
  let scheme = call_594043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594043.url(scheme.get, call_594043.host, call_594043.base,
                         call_594043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594043, url, valid)

proc call*(call_594044: Call_UpdateThingShadow_594031; thingName: string;
          body: JsonNode): Recallable =
  ## updateThingShadow
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  ##   body: JObject (required)
  var path_594045 = newJObject()
  var body_594046 = newJObject()
  add(path_594045, "thingName", newJString(thingName))
  if body != nil:
    body_594046 = body
  result = call_594044.call(path_594045, nil, nil, nil, body_594046)

var updateThingShadow* = Call_UpdateThingShadow_594031(name: "updateThingShadow",
    meth: HttpMethod.HttpPost, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_UpdateThingShadow_594032,
    base: "/", url: url_UpdateThingShadow_594033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThingShadow_593761 = ref object of OpenApiRestCall_593424
proc url_GetThingShadow_593763(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
               (kind: VariableSegment, value: "thingName"),
               (kind: ConstantSegment, value: "/shadow")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetThingShadow_593762(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_593889 = path.getOrDefault("thingName")
  valid_593889 = validateParameter(valid_593889, JString, required = true,
                                 default = nil)
  if valid_593889 != nil:
    section.add "thingName", valid_593889
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
  var valid_593890 = header.getOrDefault("X-Amz-Date")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Date", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Security-Token")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Security-Token", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Content-Sha256", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Algorithm")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Algorithm", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Signature")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Signature", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-SignedHeaders", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Credential")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Credential", valid_593896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593919: Call_GetThingShadow_593761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_593919.validator(path, query, header, formData, body)
  let scheme = call_593919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593919.url(scheme.get, call_593919.host, call_593919.base,
                         call_593919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593919, url, valid)

proc call*(call_593990: Call_GetThingShadow_593761; thingName: string): Recallable =
  ## getThingShadow
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_593991 = newJObject()
  add(path_593991, "thingName", newJString(thingName))
  result = call_593990.call(path_593991, nil, nil, nil, nil)

var getThingShadow* = Call_GetThingShadow_593761(name: "getThingShadow",
    meth: HttpMethod.HttpGet, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_GetThingShadow_593762,
    base: "/", url: url_GetThingShadow_593763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThingShadow_594047 = ref object of OpenApiRestCall_593424
proc url_DeleteThingShadow_594049(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
               (kind: VariableSegment, value: "thingName"),
               (kind: ConstantSegment, value: "/shadow")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteThingShadow_594048(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_594050 = path.getOrDefault("thingName")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "thingName", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594058: Call_DeleteThingShadow_594047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_594058.validator(path, query, header, formData, body)
  let scheme = call_594058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594058.url(scheme.get, call_594058.host, call_594058.base,
                         call_594058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594058, url, valid)

proc call*(call_594059: Call_DeleteThingShadow_594047; thingName: string): Recallable =
  ## deleteThingShadow
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_594060 = newJObject()
  add(path_594060, "thingName", newJString(thingName))
  result = call_594059.call(path_594060, nil, nil, nil, nil)

var deleteThingShadow* = Call_DeleteThingShadow_594047(name: "deleteThingShadow",
    meth: HttpMethod.HttpDelete, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_DeleteThingShadow_594048,
    base: "/", url: url_DeleteThingShadow_594049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Publish_594061 = ref object of OpenApiRestCall_593424
proc url_Publish_594063(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "topic" in path, "`topic` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/topics/"),
               (kind: VariableSegment, value: "topic")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_Publish_594062(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   topic: JString (required)
  ##        : The name of the MQTT topic.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `topic` field"
  var valid_594064 = path.getOrDefault("topic")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "topic", valid_594064
  result.add "path", section
  ## parameters in `query` object:
  ##   qos: JInt
  ##      : The Quality of Service (QoS) level.
  section = newJObject()
  var valid_594065 = query.getOrDefault("qos")
  valid_594065 = validateParameter(valid_594065, JInt, required = false, default = nil)
  if valid_594065 != nil:
    section.add "qos", valid_594065
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
  var valid_594066 = header.getOrDefault("X-Amz-Date")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Date", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Security-Token")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Security-Token", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Content-Sha256", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Algorithm")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Algorithm", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Signature")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Signature", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-SignedHeaders", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594074: Call_Publish_594061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_594074.validator(path, query, header, formData, body)
  let scheme = call_594074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594074.url(scheme.get, call_594074.host, call_594074.base,
                         call_594074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594074, url, valid)

proc call*(call_594075: Call_Publish_594061; topic: string; body: JsonNode;
          qos: int = 0): Recallable =
  ## publish
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   qos: int
  ##      : The Quality of Service (QoS) level.
  ##   topic: string (required)
  ##        : The name of the MQTT topic.
  ##   body: JObject (required)
  var path_594076 = newJObject()
  var query_594077 = newJObject()
  var body_594078 = newJObject()
  add(query_594077, "qos", newJInt(qos))
  add(path_594076, "topic", newJString(topic))
  if body != nil:
    body_594078 = body
  result = call_594075.call(path_594076, query_594077, nil, nil, body_594078)

var publish* = Call_Publish_594061(name: "publish", meth: HttpMethod.HttpPost,
                                host: "data.iot.amazonaws.com",
                                route: "/topics/{topic}",
                                validator: validate_Publish_594062, base: "/",
                                url: url_Publish_594063,
                                schemes: {Scheme.Https, Scheme.Http})
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
