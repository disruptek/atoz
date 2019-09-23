
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600424): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  Call_UpdateThingShadow_601031 = ref object of OpenApiRestCall_600424
proc url_UpdateThingShadow_601033(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateThingShadow_601032(path: JsonNode; query: JsonNode;
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
  var valid_601034 = path.getOrDefault("thingName")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "thingName", valid_601034
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601043: Call_UpdateThingShadow_601031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_601043.validator(path, query, header, formData, body)
  let scheme = call_601043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601043.url(scheme.get, call_601043.host, call_601043.base,
                         call_601043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601043, url, valid)

proc call*(call_601044: Call_UpdateThingShadow_601031; thingName: string;
          body: JsonNode): Recallable =
  ## updateThingShadow
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  ##   body: JObject (required)
  var path_601045 = newJObject()
  var body_601046 = newJObject()
  add(path_601045, "thingName", newJString(thingName))
  if body != nil:
    body_601046 = body
  result = call_601044.call(path_601045, nil, nil, nil, body_601046)

var updateThingShadow* = Call_UpdateThingShadow_601031(name: "updateThingShadow",
    meth: HttpMethod.HttpPost, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_UpdateThingShadow_601032,
    base: "/", url: url_UpdateThingShadow_601033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThingShadow_600761 = ref object of OpenApiRestCall_600424
proc url_GetThingShadow_600763(protocol: Scheme; host: string; base: string;
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

proc validate_GetThingShadow_600762(path: JsonNode; query: JsonNode;
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
  var valid_600889 = path.getOrDefault("thingName")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = nil)
  if valid_600889 != nil:
    section.add "thingName", valid_600889
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
  var valid_600890 = header.getOrDefault("X-Amz-Date")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Date", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Security-Token")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Security-Token", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Content-Sha256", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Algorithm")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Algorithm", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Signature")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Signature", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-SignedHeaders", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Credential")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Credential", valid_600896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600919: Call_GetThingShadow_600761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_600919.validator(path, query, header, formData, body)
  let scheme = call_600919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600919.url(scheme.get, call_600919.host, call_600919.base,
                         call_600919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600919, url, valid)

proc call*(call_600990: Call_GetThingShadow_600761; thingName: string): Recallable =
  ## getThingShadow
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_600991 = newJObject()
  add(path_600991, "thingName", newJString(thingName))
  result = call_600990.call(path_600991, nil, nil, nil, nil)

var getThingShadow* = Call_GetThingShadow_600761(name: "getThingShadow",
    meth: HttpMethod.HttpGet, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_GetThingShadow_600762,
    base: "/", url: url_GetThingShadow_600763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThingShadow_601047 = ref object of OpenApiRestCall_600424
proc url_DeleteThingShadow_601049(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteThingShadow_601048(path: JsonNode; query: JsonNode;
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
  var valid_601050 = path.getOrDefault("thingName")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "thingName", valid_601050
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
  var valid_601051 = header.getOrDefault("X-Amz-Date")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Date", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Security-Token")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Security-Token", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Content-Sha256", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Algorithm")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Algorithm", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Signature")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Signature", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-SignedHeaders", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Credential")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Credential", valid_601057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_DeleteThingShadow_601047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_DeleteThingShadow_601047; thingName: string): Recallable =
  ## deleteThingShadow
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_601060 = newJObject()
  add(path_601060, "thingName", newJString(thingName))
  result = call_601059.call(path_601060, nil, nil, nil, nil)

var deleteThingShadow* = Call_DeleteThingShadow_601047(name: "deleteThingShadow",
    meth: HttpMethod.HttpDelete, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_DeleteThingShadow_601048,
    base: "/", url: url_DeleteThingShadow_601049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Publish_601061 = ref object of OpenApiRestCall_600424
proc url_Publish_601063(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Publish_601062(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601064 = path.getOrDefault("topic")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "topic", valid_601064
  result.add "path", section
  ## parameters in `query` object:
  ##   qos: JInt
  ##      : The Quality of Service (QoS) level.
  section = newJObject()
  var valid_601065 = query.getOrDefault("qos")
  valid_601065 = validateParameter(valid_601065, JInt, required = false, default = nil)
  if valid_601065 != nil:
    section.add "qos", valid_601065
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
  var valid_601066 = header.getOrDefault("X-Amz-Date")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Date", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Security-Token")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Security-Token", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Content-Sha256", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Algorithm")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Algorithm", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Signature")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Signature", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-SignedHeaders", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Credential")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Credential", valid_601072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601074: Call_Publish_601061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_601074.validator(path, query, header, formData, body)
  let scheme = call_601074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601074.url(scheme.get, call_601074.host, call_601074.base,
                         call_601074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601074, url, valid)

proc call*(call_601075: Call_Publish_601061; topic: string; body: JsonNode;
          qos: int = 0): Recallable =
  ## publish
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   qos: int
  ##      : The Quality of Service (QoS) level.
  ##   topic: string (required)
  ##        : The name of the MQTT topic.
  ##   body: JObject (required)
  var path_601076 = newJObject()
  var query_601077 = newJObject()
  var body_601078 = newJObject()
  add(query_601077, "qos", newJInt(qos))
  add(path_601076, "topic", newJString(topic))
  if body != nil:
    body_601078 = body
  result = call_601075.call(path_601076, query_601077, nil, nil, body_601078)

var publish* = Call_Publish_601061(name: "publish", meth: HttpMethod.HttpPost,
                                host: "data.iot.amazonaws.com",
                                route: "/topics/{topic}",
                                validator: validate_Publish_601062, base: "/",
                                url: url_Publish_601063,
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
