
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_UpdateThingShadow_613257 = ref object of OpenApiRestCall_612649
proc url_UpdateThingShadow_613259(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateThingShadow_613258(path: JsonNode; query: JsonNode;
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
  var valid_613260 = path.getOrDefault("thingName")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = nil)
  if valid_613260 != nil:
    section.add "thingName", valid_613260
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
  var valid_613261 = header.getOrDefault("X-Amz-Signature")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Signature", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Content-Sha256", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Date")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Date", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Credential")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Credential", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Security-Token")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Security-Token", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-Algorithm")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Algorithm", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-SignedHeaders", valid_613267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613269: Call_UpdateThingShadow_613257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_613269.validator(path, query, header, formData, body)
  let scheme = call_613269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613269.url(scheme.get, call_613269.host, call_613269.base,
                         call_613269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613269, url, valid)

proc call*(call_613270: Call_UpdateThingShadow_613257; thingName: string;
          body: JsonNode): Recallable =
  ## updateThingShadow
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  ##   body: JObject (required)
  var path_613271 = newJObject()
  var body_613272 = newJObject()
  add(path_613271, "thingName", newJString(thingName))
  if body != nil:
    body_613272 = body
  result = call_613270.call(path_613271, nil, nil, nil, body_613272)

var updateThingShadow* = Call_UpdateThingShadow_613257(name: "updateThingShadow",
    meth: HttpMethod.HttpPost, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_UpdateThingShadow_613258,
    base: "/", url: url_UpdateThingShadow_613259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThingShadow_612987 = ref object of OpenApiRestCall_612649
proc url_GetThingShadow_612989(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetThingShadow_612988(path: JsonNode; query: JsonNode;
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
  var valid_613115 = path.getOrDefault("thingName")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "thingName", valid_613115
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
  var valid_613116 = header.getOrDefault("X-Amz-Signature")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Signature", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Content-Sha256", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Date")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Date", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Credential")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Credential", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Security-Token")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Security-Token", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Algorithm")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Algorithm", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-SignedHeaders", valid_613122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_GetThingShadow_612987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_GetThingShadow_612987; thingName: string): Recallable =
  ## getThingShadow
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_613217 = newJObject()
  add(path_613217, "thingName", newJString(thingName))
  result = call_613216.call(path_613217, nil, nil, nil, nil)

var getThingShadow* = Call_GetThingShadow_612987(name: "getThingShadow",
    meth: HttpMethod.HttpGet, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_GetThingShadow_612988,
    base: "/", url: url_GetThingShadow_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThingShadow_613273 = ref object of OpenApiRestCall_612649
proc url_DeleteThingShadow_613275(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteThingShadow_613274(path: JsonNode; query: JsonNode;
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
  var valid_613276 = path.getOrDefault("thingName")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = nil)
  if valid_613276 != nil:
    section.add "thingName", valid_613276
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
  var valid_613277 = header.getOrDefault("X-Amz-Signature")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Signature", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Content-Sha256", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Date")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Date", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Credential")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Credential", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Security-Token")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Security-Token", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Algorithm")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Algorithm", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-SignedHeaders", valid_613283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_DeleteThingShadow_613273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_DeleteThingShadow_613273; thingName: string): Recallable =
  ## deleteThingShadow
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_613286 = newJObject()
  add(path_613286, "thingName", newJString(thingName))
  result = call_613285.call(path_613286, nil, nil, nil, nil)

var deleteThingShadow* = Call_DeleteThingShadow_613273(name: "deleteThingShadow",
    meth: HttpMethod.HttpDelete, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_DeleteThingShadow_613274,
    base: "/", url: url_DeleteThingShadow_613275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Publish_613287 = ref object of OpenApiRestCall_612649
proc url_Publish_613289(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Publish_613288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613290 = path.getOrDefault("topic")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "topic", valid_613290
  result.add "path", section
  ## parameters in `query` object:
  ##   qos: JInt
  ##      : The Quality of Service (QoS) level.
  section = newJObject()
  var valid_613291 = query.getOrDefault("qos")
  valid_613291 = validateParameter(valid_613291, JInt, required = false, default = nil)
  if valid_613291 != nil:
    section.add "qos", valid_613291
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
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Security-Token")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Security-Token", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Algorithm")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Algorithm", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-SignedHeaders", valid_613298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613300: Call_Publish_613287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_613300.validator(path, query, header, formData, body)
  let scheme = call_613300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613300.url(scheme.get, call_613300.host, call_613300.base,
                         call_613300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613300, url, valid)

proc call*(call_613301: Call_Publish_613287; topic: string; body: JsonNode;
          qos: int = 0): Recallable =
  ## publish
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   qos: int
  ##      : The Quality of Service (QoS) level.
  ##   topic: string (required)
  ##        : The name of the MQTT topic.
  ##   body: JObject (required)
  var path_613302 = newJObject()
  var query_613303 = newJObject()
  var body_613304 = newJObject()
  add(query_613303, "qos", newJInt(qos))
  add(path_613302, "topic", newJString(topic))
  if body != nil:
    body_613304 = body
  result = call_613301.call(path_613302, query_613303, nil, nil, body_613304)

var publish* = Call_Publish_613287(name: "publish", meth: HttpMethod.HttpPost,
                                host: "data.iot.amazonaws.com",
                                route: "/topics/{topic}",
                                validator: validate_Publish_613288, base: "/",
                                url: url_Publish_613289,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
