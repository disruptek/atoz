
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_UpdateThingShadow_599966 = ref object of OpenApiRestCall_599359
proc url_UpdateThingShadow_599968(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateThingShadow_599967(path: JsonNode; query: JsonNode;
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
  var valid_599969 = path.getOrDefault("thingName")
  valid_599969 = validateParameter(valid_599969, JString, required = true,
                                 default = nil)
  if valid_599969 != nil:
    section.add "thingName", valid_599969
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
  var valid_599970 = header.getOrDefault("X-Amz-Date")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Date", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Security-Token")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Security-Token", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Content-Sha256", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Algorithm")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Algorithm", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Signature")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Signature", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-SignedHeaders", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Credential")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Credential", valid_599976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599978: Call_UpdateThingShadow_599966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_599978.validator(path, query, header, formData, body)
  let scheme = call_599978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599978.url(scheme.get, call_599978.host, call_599978.base,
                         call_599978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599978, url, valid)

proc call*(call_599979: Call_UpdateThingShadow_599966; thingName: string;
          body: JsonNode): Recallable =
  ## updateThingShadow
  ## <p>Updates the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html">UpdateThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  ##   body: JObject (required)
  var path_599980 = newJObject()
  var body_599981 = newJObject()
  add(path_599980, "thingName", newJString(thingName))
  if body != nil:
    body_599981 = body
  result = call_599979.call(path_599980, nil, nil, nil, body_599981)

var updateThingShadow* = Call_UpdateThingShadow_599966(name: "updateThingShadow",
    meth: HttpMethod.HttpPost, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_UpdateThingShadow_599967,
    base: "/", url: url_UpdateThingShadow_599968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThingShadow_599696 = ref object of OpenApiRestCall_599359
proc url_GetThingShadow_599698(protocol: Scheme; host: string; base: string;
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

proc validate_GetThingShadow_599697(path: JsonNode; query: JsonNode;
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
  var valid_599824 = path.getOrDefault("thingName")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "thingName", valid_599824
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
  var valid_599825 = header.getOrDefault("X-Amz-Date")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Date", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Security-Token")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Security-Token", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Content-Sha256", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Algorithm")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Algorithm", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Signature")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Signature", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-SignedHeaders", valid_599830
  var valid_599831 = header.getOrDefault("X-Amz-Credential")
  valid_599831 = validateParameter(valid_599831, JString, required = false,
                                 default = nil)
  if valid_599831 != nil:
    section.add "X-Amz-Credential", valid_599831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599854: Call_GetThingShadow_599696; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_599854.validator(path, query, header, formData, body)
  let scheme = call_599854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599854.url(scheme.get, call_599854.host, call_599854.base,
                         call_599854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599854, url, valid)

proc call*(call_599925: Call_GetThingShadow_599696; thingName: string): Recallable =
  ## getThingShadow
  ## <p>Gets the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html">GetThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_599926 = newJObject()
  add(path_599926, "thingName", newJString(thingName))
  result = call_599925.call(path_599926, nil, nil, nil, nil)

var getThingShadow* = Call_GetThingShadow_599696(name: "getThingShadow",
    meth: HttpMethod.HttpGet, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_GetThingShadow_599697,
    base: "/", url: url_GetThingShadow_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThingShadow_599982 = ref object of OpenApiRestCall_599359
proc url_DeleteThingShadow_599984(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteThingShadow_599983(path: JsonNode; query: JsonNode;
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
  var valid_599985 = path.getOrDefault("thingName")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = nil)
  if valid_599985 != nil:
    section.add "thingName", valid_599985
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
  var valid_599986 = header.getOrDefault("X-Amz-Date")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Date", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Security-Token")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Security-Token", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Content-Sha256", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Algorithm")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Algorithm", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Signature")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Signature", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-SignedHeaders", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Credential")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Credential", valid_599992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599993: Call_DeleteThingShadow_599982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_599993.validator(path, query, header, formData, body)
  let scheme = call_599993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599993.url(scheme.get, call_599993.host, call_599993.base,
                         call_599993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599993, url, valid)

proc call*(call_599994: Call_DeleteThingShadow_599982; thingName: string): Recallable =
  ## deleteThingShadow
  ## <p>Deletes the thing shadow for the specified thing.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html">DeleteThingShadow</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   thingName: string (required)
  ##            : The name of the thing.
  var path_599995 = newJObject()
  add(path_599995, "thingName", newJString(thingName))
  result = call_599994.call(path_599995, nil, nil, nil, nil)

var deleteThingShadow* = Call_DeleteThingShadow_599982(name: "deleteThingShadow",
    meth: HttpMethod.HttpDelete, host: "data.iot.amazonaws.com",
    route: "/things/{thingName}/shadow", validator: validate_DeleteThingShadow_599983,
    base: "/", url: url_DeleteThingShadow_599984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Publish_599996 = ref object of OpenApiRestCall_599359
proc url_Publish_599998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Publish_599997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599999 = path.getOrDefault("topic")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = nil)
  if valid_599999 != nil:
    section.add "topic", valid_599999
  result.add "path", section
  ## parameters in `query` object:
  ##   qos: JInt
  ##      : The Quality of Service (QoS) level.
  section = newJObject()
  var valid_600000 = query.getOrDefault("qos")
  valid_600000 = validateParameter(valid_600000, JInt, required = false, default = nil)
  if valid_600000 != nil:
    section.add "qos", valid_600000
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
  var valid_600001 = header.getOrDefault("X-Amz-Date")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Date", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Security-Token")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Security-Token", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Content-Sha256", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Algorithm")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Algorithm", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Signature")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Signature", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-SignedHeaders", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Credential")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Credential", valid_600007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600009: Call_Publish_599996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ## 
  let valid = call_600009.validator(path, query, header, formData, body)
  let scheme = call_600009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600009.url(scheme.get, call_600009.host, call_600009.base,
                         call_600009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600009, url, valid)

proc call*(call_600010: Call_Publish_599996; topic: string; body: JsonNode;
          qos: int = 0): Recallable =
  ## publish
  ## <p>Publishes state information.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/iot/latest/developerguide/protocols.html#http">HTTP Protocol</a> in the <i>AWS IoT Developer Guide</i>.</p>
  ##   qos: int
  ##      : The Quality of Service (QoS) level.
  ##   topic: string (required)
  ##        : The name of the MQTT topic.
  ##   body: JObject (required)
  var path_600011 = newJObject()
  var query_600012 = newJObject()
  var body_600013 = newJObject()
  add(query_600012, "qos", newJInt(qos))
  add(path_600011, "topic", newJString(topic))
  if body != nil:
    body_600013 = body
  result = call_600010.call(path_600011, query_600012, nil, nil, body_600013)

var publish* = Call_Publish_599996(name: "publish", meth: HttpMethod.HttpPost,
                                host: "data.iot.amazonaws.com",
                                route: "/topics/{topic}",
                                validator: validate_Publish_599997, base: "/",
                                url: url_Publish_599998,
                                schemes: {Scheme.Https, Scheme.Http})
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
