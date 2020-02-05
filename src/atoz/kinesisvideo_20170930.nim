
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Video Streams
## version: 2017-09-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kinesisvideo/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kinesisvideo.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kinesisvideo.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kinesisvideo.us-west-2.amazonaws.com",
                           "eu-west-2": "kinesisvideo.eu-west-2.amazonaws.com", "ap-northeast-3": "kinesisvideo.ap-northeast-3.amazonaws.com", "eu-central-1": "kinesisvideo.eu-central-1.amazonaws.com",
                           "us-east-2": "kinesisvideo.us-east-2.amazonaws.com",
                           "us-east-1": "kinesisvideo.us-east-1.amazonaws.com", "cn-northwest-1": "kinesisvideo.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "kinesisvideo.ap-south-1.amazonaws.com", "eu-north-1": "kinesisvideo.eu-north-1.amazonaws.com", "ap-northeast-2": "kinesisvideo.ap-northeast-2.amazonaws.com",
                           "us-west-1": "kinesisvideo.us-west-1.amazonaws.com", "us-gov-east-1": "kinesisvideo.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "kinesisvideo.eu-west-3.amazonaws.com", "cn-north-1": "kinesisvideo.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "kinesisvideo.sa-east-1.amazonaws.com",
                           "eu-west-1": "kinesisvideo.eu-west-1.amazonaws.com", "us-gov-west-1": "kinesisvideo.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kinesisvideo.ap-southeast-2.amazonaws.com", "ca-central-1": "kinesisvideo.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "kinesisvideo.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kinesisvideo.ap-southeast-1.amazonaws.com",
      "us-west-2": "kinesisvideo.us-west-2.amazonaws.com",
      "eu-west-2": "kinesisvideo.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kinesisvideo.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kinesisvideo.eu-central-1.amazonaws.com",
      "us-east-2": "kinesisvideo.us-east-2.amazonaws.com",
      "us-east-1": "kinesisvideo.us-east-1.amazonaws.com",
      "cn-northwest-1": "kinesisvideo.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kinesisvideo.ap-south-1.amazonaws.com",
      "eu-north-1": "kinesisvideo.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kinesisvideo.ap-northeast-2.amazonaws.com",
      "us-west-1": "kinesisvideo.us-west-1.amazonaws.com",
      "us-gov-east-1": "kinesisvideo.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kinesisvideo.eu-west-3.amazonaws.com",
      "cn-north-1": "kinesisvideo.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kinesisvideo.sa-east-1.amazonaws.com",
      "eu-west-1": "kinesisvideo.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kinesisvideo.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kinesisvideo.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kinesisvideo.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kinesisvideo"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateSignalingChannel_612996 = ref object of OpenApiRestCall_612658
proc url_CreateSignalingChannel_612998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSignalingChannel_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a signaling channel. </p> <p> <code>CreateSignalingChannel</code> is an asynchronous operation.</p>
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
  var valid_613110 = header.getOrDefault("X-Amz-Signature")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Signature", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Content-Sha256", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Date")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Date", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Credential")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Credential", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Security-Token")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Security-Token", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Algorithm")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Algorithm", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-SignedHeaders", valid_613116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_CreateSignalingChannel_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a signaling channel. </p> <p> <code>CreateSignalingChannel</code> is an asynchronous operation.</p>
  ## 
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_CreateSignalingChannel_612996; body: JsonNode): Recallable =
  ## createSignalingChannel
  ## <p>Creates a signaling channel. </p> <p> <code>CreateSignalingChannel</code> is an asynchronous operation.</p>
  ##   body: JObject (required)
  var body_613212 = newJObject()
  if body != nil:
    body_613212 = body
  result = call_613211.call(nil, nil, nil, nil, body_613212)

var createSignalingChannel* = Call_CreateSignalingChannel_612996(
    name: "createSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/createSignalingChannel",
    validator: validate_CreateSignalingChannel_612997, base: "/",
    url: url_CreateSignalingChannel_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStream_613251 = ref object of OpenApiRestCall_612658
proc url_CreateStream_613253(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStream_613252(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Kinesis video stream. </p> <p>When you create a new stream, Kinesis Video Streams assigns it a version number. When you change the stream's metadata, Kinesis Video Streams updates the version. </p> <p> <code>CreateStream</code> is an asynchronous operation.</p> <p>For information about how the service works, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-it-works.html">How it Works</a>. </p> <p>You must have permissions for the <code>KinesisVideo:CreateStream</code> action.</p>
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
  var valid_613254 = header.getOrDefault("X-Amz-Signature")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Signature", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Content-Sha256", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Date")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Date", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Credential")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Credential", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Security-Token")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Security-Token", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Algorithm")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Algorithm", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-SignedHeaders", valid_613260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613262: Call_CreateStream_613251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Kinesis video stream. </p> <p>When you create a new stream, Kinesis Video Streams assigns it a version number. When you change the stream's metadata, Kinesis Video Streams updates the version. </p> <p> <code>CreateStream</code> is an asynchronous operation.</p> <p>For information about how the service works, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-it-works.html">How it Works</a>. </p> <p>You must have permissions for the <code>KinesisVideo:CreateStream</code> action.</p>
  ## 
  let valid = call_613262.validator(path, query, header, formData, body)
  let scheme = call_613262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613262.url(scheme.get, call_613262.host, call_613262.base,
                         call_613262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613262, url, valid)

proc call*(call_613263: Call_CreateStream_613251; body: JsonNode): Recallable =
  ## createStream
  ## <p>Creates a new Kinesis video stream. </p> <p>When you create a new stream, Kinesis Video Streams assigns it a version number. When you change the stream's metadata, Kinesis Video Streams updates the version. </p> <p> <code>CreateStream</code> is an asynchronous operation.</p> <p>For information about how the service works, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-it-works.html">How it Works</a>. </p> <p>You must have permissions for the <code>KinesisVideo:CreateStream</code> action.</p>
  ##   body: JObject (required)
  var body_613264 = newJObject()
  if body != nil:
    body_613264 = body
  result = call_613263.call(nil, nil, nil, nil, body_613264)

var createStream* = Call_CreateStream_613251(name: "createStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/createStream", validator: validate_CreateStream_613252, base: "/",
    url: url_CreateStream_613253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSignalingChannel_613265 = ref object of OpenApiRestCall_612658
proc url_DeleteSignalingChannel_613267(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSignalingChannel_613266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified signaling channel. <code>DeleteSignalingChannel</code> is an asynchronous operation. If you don't specify the channel's current version, the most recent version is deleted.
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
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_DeleteSignalingChannel_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified signaling channel. <code>DeleteSignalingChannel</code> is an asynchronous operation. If you don't specify the channel's current version, the most recent version is deleted.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_DeleteSignalingChannel_613265; body: JsonNode): Recallable =
  ## deleteSignalingChannel
  ## Deletes a specified signaling channel. <code>DeleteSignalingChannel</code> is an asynchronous operation. If you don't specify the channel's current version, the most recent version is deleted.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var deleteSignalingChannel* = Call_DeleteSignalingChannel_613265(
    name: "deleteSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/deleteSignalingChannel",
    validator: validate_DeleteSignalingChannel_613266, base: "/",
    url: url_DeleteSignalingChannel_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStream_613279 = ref object of OpenApiRestCall_612658
proc url_DeleteStream_613281(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStream_613280(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a Kinesis video stream and the data contained in the stream. </p> <p>This method marks the stream for deletion, and makes the data in the stream inaccessible immediately.</p> <p> </p> <p> To ensure that you have the latest version of the stream before deleting it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p>This operation requires permission for the <code>KinesisVideo:DeleteStream</code> action.</p>
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
  var valid_613282 = header.getOrDefault("X-Amz-Signature")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Signature", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Content-Sha256", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Date")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Date", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Credential")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Credential", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Security-Token")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Security-Token", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Algorithm")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Algorithm", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-SignedHeaders", valid_613288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613290: Call_DeleteStream_613279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Kinesis video stream and the data contained in the stream. </p> <p>This method marks the stream for deletion, and makes the data in the stream inaccessible immediately.</p> <p> </p> <p> To ensure that you have the latest version of the stream before deleting it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p>This operation requires permission for the <code>KinesisVideo:DeleteStream</code> action.</p>
  ## 
  let valid = call_613290.validator(path, query, header, formData, body)
  let scheme = call_613290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613290.url(scheme.get, call_613290.host, call_613290.base,
                         call_613290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613290, url, valid)

proc call*(call_613291: Call_DeleteStream_613279; body: JsonNode): Recallable =
  ## deleteStream
  ## <p>Deletes a Kinesis video stream and the data contained in the stream. </p> <p>This method marks the stream for deletion, and makes the data in the stream inaccessible immediately.</p> <p> </p> <p> To ensure that you have the latest version of the stream before deleting it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p>This operation requires permission for the <code>KinesisVideo:DeleteStream</code> action.</p>
  ##   body: JObject (required)
  var body_613292 = newJObject()
  if body != nil:
    body_613292 = body
  result = call_613291.call(nil, nil, nil, nil, body_613292)

var deleteStream* = Call_DeleteStream_613279(name: "deleteStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/deleteStream", validator: validate_DeleteStream_613280, base: "/",
    url: url_DeleteStream_613281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSignalingChannel_613293 = ref object of OpenApiRestCall_612658
proc url_DescribeSignalingChannel_613295(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSignalingChannel_613294(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the most current information about the signaling channel. You must specify either the name or the ARN of the channel that you want to describe.
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
  var valid_613296 = header.getOrDefault("X-Amz-Signature")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Signature", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Content-Sha256", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Date")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Date", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Credential")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Credential", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Security-Token")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Security-Token", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Algorithm")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Algorithm", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-SignedHeaders", valid_613302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613304: Call_DescribeSignalingChannel_613293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the most current information about the signaling channel. You must specify either the name or the ARN of the channel that you want to describe.
  ## 
  let valid = call_613304.validator(path, query, header, formData, body)
  let scheme = call_613304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613304.url(scheme.get, call_613304.host, call_613304.base,
                         call_613304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613304, url, valid)

proc call*(call_613305: Call_DescribeSignalingChannel_613293; body: JsonNode): Recallable =
  ## describeSignalingChannel
  ## Returns the most current information about the signaling channel. You must specify either the name or the ARN of the channel that you want to describe.
  ##   body: JObject (required)
  var body_613306 = newJObject()
  if body != nil:
    body_613306 = body
  result = call_613305.call(nil, nil, nil, nil, body_613306)

var describeSignalingChannel* = Call_DescribeSignalingChannel_613293(
    name: "describeSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/describeSignalingChannel",
    validator: validate_DescribeSignalingChannel_613294, base: "/",
    url: url_DescribeSignalingChannel_613295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStream_613307 = ref object of OpenApiRestCall_612658
proc url_DescribeStream_613309(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeStream_613308(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the most current information about the specified stream. You must specify either the <code>StreamName</code> or the <code>StreamARN</code>. 
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
  var valid_613310 = header.getOrDefault("X-Amz-Signature")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Signature", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Content-Sha256", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Date")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Date", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Credential")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Credential", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Security-Token")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Security-Token", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Algorithm")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Algorithm", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-SignedHeaders", valid_613316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613318: Call_DescribeStream_613307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the most current information about the specified stream. You must specify either the <code>StreamName</code> or the <code>StreamARN</code>. 
  ## 
  let valid = call_613318.validator(path, query, header, formData, body)
  let scheme = call_613318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613318.url(scheme.get, call_613318.host, call_613318.base,
                         call_613318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613318, url, valid)

proc call*(call_613319: Call_DescribeStream_613307; body: JsonNode): Recallable =
  ## describeStream
  ## Returns the most current information about the specified stream. You must specify either the <code>StreamName</code> or the <code>StreamARN</code>. 
  ##   body: JObject (required)
  var body_613320 = newJObject()
  if body != nil:
    body_613320 = body
  result = call_613319.call(nil, nil, nil, nil, body_613320)

var describeStream* = Call_DescribeStream_613307(name: "describeStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/describeStream", validator: validate_DescribeStream_613308, base: "/",
    url: url_DescribeStream_613309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataEndpoint_613321 = ref object of OpenApiRestCall_612658
proc url_GetDataEndpoint_613323(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataEndpoint_613322(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Gets an endpoint for a specified stream for either reading or writing. Use this endpoint in your application to read from the specified stream (using the <code>GetMedia</code> or <code>GetMediaForFragmentList</code> operations) or write to it (using the <code>PutMedia</code> operation). </p> <note> <p>The returned endpoint does not have the API name appended. The client needs to add the API name to the returned endpoint.</p> </note> <p>In the request, specify the stream either by <code>StreamName</code> or <code>StreamARN</code>.</p>
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
  var valid_613324 = header.getOrDefault("X-Amz-Signature")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Signature", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Content-Sha256", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Date")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Date", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Credential")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Credential", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Security-Token")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Security-Token", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Algorithm")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Algorithm", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-SignedHeaders", valid_613330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613332: Call_GetDataEndpoint_613321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets an endpoint for a specified stream for either reading or writing. Use this endpoint in your application to read from the specified stream (using the <code>GetMedia</code> or <code>GetMediaForFragmentList</code> operations) or write to it (using the <code>PutMedia</code> operation). </p> <note> <p>The returned endpoint does not have the API name appended. The client needs to add the API name to the returned endpoint.</p> </note> <p>In the request, specify the stream either by <code>StreamName</code> or <code>StreamARN</code>.</p>
  ## 
  let valid = call_613332.validator(path, query, header, formData, body)
  let scheme = call_613332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613332.url(scheme.get, call_613332.host, call_613332.base,
                         call_613332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613332, url, valid)

proc call*(call_613333: Call_GetDataEndpoint_613321; body: JsonNode): Recallable =
  ## getDataEndpoint
  ## <p>Gets an endpoint for a specified stream for either reading or writing. Use this endpoint in your application to read from the specified stream (using the <code>GetMedia</code> or <code>GetMediaForFragmentList</code> operations) or write to it (using the <code>PutMedia</code> operation). </p> <note> <p>The returned endpoint does not have the API name appended. The client needs to add the API name to the returned endpoint.</p> </note> <p>In the request, specify the stream either by <code>StreamName</code> or <code>StreamARN</code>.</p>
  ##   body: JObject (required)
  var body_613334 = newJObject()
  if body != nil:
    body_613334 = body
  result = call_613333.call(nil, nil, nil, nil, body_613334)

var getDataEndpoint* = Call_GetDataEndpoint_613321(name: "getDataEndpoint",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/getDataEndpoint", validator: validate_GetDataEndpoint_613322,
    base: "/", url: url_GetDataEndpoint_613323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSignalingChannelEndpoint_613335 = ref object of OpenApiRestCall_612658
proc url_GetSignalingChannelEndpoint_613337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSignalingChannelEndpoint_613336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Provides an endpoint for the specified signaling channel to send and receive messages. This API uses the <code>SingleMasterChannelEndpointConfiguration</code> input parameter, which consists of the <code>Protocols</code> and <code>Role</code> properties.</p> <p> <code>Protocols</code> is used to determine the communication mechanism. For example, specifying <code>WSS</code> as the protocol, results in this API producing a secure websocket endpoint, and specifying <code>HTTPS</code> as the protocol, results in this API generating an HTTPS endpoint. </p> <p> <code>Role</code> determines the messaging permissions. A <code>MASTER</code> role results in this API generating an endpoint that a client can use to communicate with any of the viewers on the channel. A <code>VIEWER</code> role results in this API generating an endpoint that a client can use to communicate only with a <code>MASTER</code>. </p>
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
  var valid_613338 = header.getOrDefault("X-Amz-Signature")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Signature", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Content-Sha256", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Date")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Date", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Credential")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Credential", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Security-Token")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Security-Token", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Algorithm")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Algorithm", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-SignedHeaders", valid_613344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613346: Call_GetSignalingChannelEndpoint_613335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides an endpoint for the specified signaling channel to send and receive messages. This API uses the <code>SingleMasterChannelEndpointConfiguration</code> input parameter, which consists of the <code>Protocols</code> and <code>Role</code> properties.</p> <p> <code>Protocols</code> is used to determine the communication mechanism. For example, specifying <code>WSS</code> as the protocol, results in this API producing a secure websocket endpoint, and specifying <code>HTTPS</code> as the protocol, results in this API generating an HTTPS endpoint. </p> <p> <code>Role</code> determines the messaging permissions. A <code>MASTER</code> role results in this API generating an endpoint that a client can use to communicate with any of the viewers on the channel. A <code>VIEWER</code> role results in this API generating an endpoint that a client can use to communicate only with a <code>MASTER</code>. </p>
  ## 
  let valid = call_613346.validator(path, query, header, formData, body)
  let scheme = call_613346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613346.url(scheme.get, call_613346.host, call_613346.base,
                         call_613346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613346, url, valid)

proc call*(call_613347: Call_GetSignalingChannelEndpoint_613335; body: JsonNode): Recallable =
  ## getSignalingChannelEndpoint
  ## <p>Provides an endpoint for the specified signaling channel to send and receive messages. This API uses the <code>SingleMasterChannelEndpointConfiguration</code> input parameter, which consists of the <code>Protocols</code> and <code>Role</code> properties.</p> <p> <code>Protocols</code> is used to determine the communication mechanism. For example, specifying <code>WSS</code> as the protocol, results in this API producing a secure websocket endpoint, and specifying <code>HTTPS</code> as the protocol, results in this API generating an HTTPS endpoint. </p> <p> <code>Role</code> determines the messaging permissions. A <code>MASTER</code> role results in this API generating an endpoint that a client can use to communicate with any of the viewers on the channel. A <code>VIEWER</code> role results in this API generating an endpoint that a client can use to communicate only with a <code>MASTER</code>. </p>
  ##   body: JObject (required)
  var body_613348 = newJObject()
  if body != nil:
    body_613348 = body
  result = call_613347.call(nil, nil, nil, nil, body_613348)

var getSignalingChannelEndpoint* = Call_GetSignalingChannelEndpoint_613335(
    name: "getSignalingChannelEndpoint", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/getSignalingChannelEndpoint",
    validator: validate_GetSignalingChannelEndpoint_613336, base: "/",
    url: url_GetSignalingChannelEndpoint_613337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSignalingChannels_613349 = ref object of OpenApiRestCall_612658
proc url_ListSignalingChannels_613351(protocol: Scheme; host: string; base: string;
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

proc validate_ListSignalingChannels_613350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>ChannelInfo</code> objects. Each object describes a signaling channel. To retrieve only those channels that satisfy a specific condition, you can specify a <code>ChannelNameCondition</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613352 = query.getOrDefault("MaxResults")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "MaxResults", valid_613352
  var valid_613353 = query.getOrDefault("NextToken")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "NextToken", valid_613353
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
  var valid_613354 = header.getOrDefault("X-Amz-Signature")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Signature", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Content-Sha256", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Date")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Date", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Credential")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Credential", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Security-Token")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Security-Token", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Algorithm")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Algorithm", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-SignedHeaders", valid_613360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613362: Call_ListSignalingChannels_613349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ChannelInfo</code> objects. Each object describes a signaling channel. To retrieve only those channels that satisfy a specific condition, you can specify a <code>ChannelNameCondition</code>.
  ## 
  let valid = call_613362.validator(path, query, header, formData, body)
  let scheme = call_613362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613362.url(scheme.get, call_613362.host, call_613362.base,
                         call_613362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613362, url, valid)

proc call*(call_613363: Call_ListSignalingChannels_613349; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSignalingChannels
  ## Returns an array of <code>ChannelInfo</code> objects. Each object describes a signaling channel. To retrieve only those channels that satisfy a specific condition, you can specify a <code>ChannelNameCondition</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613364 = newJObject()
  var body_613365 = newJObject()
  add(query_613364, "MaxResults", newJString(MaxResults))
  add(query_613364, "NextToken", newJString(NextToken))
  if body != nil:
    body_613365 = body
  result = call_613363.call(nil, query_613364, nil, nil, body_613365)

var listSignalingChannels* = Call_ListSignalingChannels_613349(
    name: "listSignalingChannels", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/listSignalingChannels",
    validator: validate_ListSignalingChannels_613350, base: "/",
    url: url_ListSignalingChannels_613351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreams_613367 = ref object of OpenApiRestCall_612658
proc url_ListStreams_613369(protocol: Scheme; host: string; base: string;
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

proc validate_ListStreams_613368(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>StreamInfo</code> objects. Each object describes a stream. To retrieve only streams that satisfy a specific condition, you can specify a <code>StreamNameCondition</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613370 = query.getOrDefault("MaxResults")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "MaxResults", valid_613370
  var valid_613371 = query.getOrDefault("NextToken")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "NextToken", valid_613371
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_ListStreams_613367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>StreamInfo</code> objects. Each object describes a stream. To retrieve only streams that satisfy a specific condition, you can specify a <code>StreamNameCondition</code>. 
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_ListStreams_613367; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreams
  ## Returns an array of <code>StreamInfo</code> objects. Each object describes a stream. To retrieve only streams that satisfy a specific condition, you can specify a <code>StreamNameCondition</code>. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613382 = newJObject()
  var body_613383 = newJObject()
  add(query_613382, "MaxResults", newJString(MaxResults))
  add(query_613382, "NextToken", newJString(NextToken))
  if body != nil:
    body_613383 = body
  result = call_613381.call(nil, query_613382, nil, nil, body_613383)

var listStreams* = Call_ListStreams_613367(name: "listStreams",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/listStreams",
                                        validator: validate_ListStreams_613368,
                                        base: "/", url: url_ListStreams_613369,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613384 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613386(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613385(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of tags associated with the specified signaling channel.
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_ListTagsForResource_613384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with the specified signaling channel.
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_ListTagsForResource_613384; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with the specified signaling channel.
  ##   body: JObject (required)
  var body_613397 = newJObject()
  if body != nil:
    body_613397 = body
  result = call_613396.call(nil, nil, nil, nil, body_613397)

var listTagsForResource* = Call_ListTagsForResource_613384(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/ListTagsForResource",
    validator: validate_ListTagsForResource_613385, base: "/",
    url: url_ListTagsForResource_613386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForStream_613398 = ref object of OpenApiRestCall_612658
proc url_ListTagsForStream_613400(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForStream_613399(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns a list of tags associated with the specified stream.</p> <p>In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p>
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
  var valid_613401 = header.getOrDefault("X-Amz-Signature")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Signature", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Content-Sha256", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Date")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Date", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Credential")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Credential", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Security-Token")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Security-Token", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Algorithm")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Algorithm", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-SignedHeaders", valid_613407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613409: Call_ListTagsForStream_613398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tags associated with the specified stream.</p> <p>In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p>
  ## 
  let valid = call_613409.validator(path, query, header, formData, body)
  let scheme = call_613409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613409.url(scheme.get, call_613409.host, call_613409.base,
                         call_613409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613409, url, valid)

proc call*(call_613410: Call_ListTagsForStream_613398; body: JsonNode): Recallable =
  ## listTagsForStream
  ## <p>Returns a list of tags associated with the specified stream.</p> <p>In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p>
  ##   body: JObject (required)
  var body_613411 = newJObject()
  if body != nil:
    body_613411 = body
  result = call_613410.call(nil, nil, nil, nil, body_613411)

var listTagsForStream* = Call_ListTagsForStream_613398(name: "listTagsForStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/listTagsForStream", validator: validate_ListTagsForStream_613399,
    base: "/", url: url_ListTagsForStream_613400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613412 = ref object of OpenApiRestCall_612658
proc url_TagResource_613414(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613413(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to a signaling channel. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.
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
  var valid_613415 = header.getOrDefault("X-Amz-Signature")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Signature", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Content-Sha256", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Date")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Date", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Credential")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Credential", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Security-Token")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Security-Token", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Algorithm")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Algorithm", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-SignedHeaders", valid_613421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613423: Call_TagResource_613412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a signaling channel. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.
  ## 
  let valid = call_613423.validator(path, query, header, formData, body)
  let scheme = call_613423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613423.url(scheme.get, call_613423.host, call_613423.base,
                         call_613423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613423, url, valid)

proc call*(call_613424: Call_TagResource_613412; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a signaling channel. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.
  ##   body: JObject (required)
  var body_613425 = newJObject()
  if body != nil:
    body_613425 = body
  result = call_613424.call(nil, nil, nil, nil, body_613425)

var tagResource* = Call_TagResource_613412(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/TagResource",
                                        validator: validate_TagResource_613413,
                                        base: "/", url: url_TagResource_613414,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagStream_613426 = ref object of OpenApiRestCall_612658
proc url_TagStream_613428(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagStream_613427(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to a stream. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>You must provide either the <code>StreamName</code> or the <code>StreamARN</code>.</p> <p>This operation requires permission for the <code>KinesisVideo:TagStream</code> action.</p> <p>Kinesis video streams support up to 50 tags.</p>
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
  var valid_613429 = header.getOrDefault("X-Amz-Signature")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Signature", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Content-Sha256", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Date")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Date", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Credential")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Credential", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Security-Token")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Security-Token", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Algorithm")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Algorithm", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-SignedHeaders", valid_613435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_TagStream_613426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a stream. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>You must provide either the <code>StreamName</code> or the <code>StreamARN</code>.</p> <p>This operation requires permission for the <code>KinesisVideo:TagStream</code> action.</p> <p>Kinesis video streams support up to 50 tags.</p>
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_TagStream_613426; body: JsonNode): Recallable =
  ## tagStream
  ## <p>Adds one or more tags to a stream. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>You must provide either the <code>StreamName</code> or the <code>StreamARN</code>.</p> <p>This operation requires permission for the <code>KinesisVideo:TagStream</code> action.</p> <p>Kinesis video streams support up to 50 tags.</p>
  ##   body: JObject (required)
  var body_613439 = newJObject()
  if body != nil:
    body_613439 = body
  result = call_613438.call(nil, nil, nil, nil, body_613439)

var tagStream* = Call_TagStream_613426(name: "tagStream", meth: HttpMethod.HttpPost,
                                    host: "kinesisvideo.amazonaws.com",
                                    route: "/tagStream",
                                    validator: validate_TagStream_613427,
                                    base: "/", url: url_TagStream_613428,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613440 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613442(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613441(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from a signaling channel. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.
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
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613451: Call_UntagResource_613440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a signaling channel. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.
  ## 
  let valid = call_613451.validator(path, query, header, formData, body)
  let scheme = call_613451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613451.url(scheme.get, call_613451.host, call_613451.base,
                         call_613451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613451, url, valid)

proc call*(call_613452: Call_UntagResource_613440; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a signaling channel. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.
  ##   body: JObject (required)
  var body_613453 = newJObject()
  if body != nil:
    body_613453 = body
  result = call_613452.call(nil, nil, nil, nil, body_613453)

var untagResource* = Call_UntagResource_613440(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/UntagResource", validator: validate_UntagResource_613441, base: "/",
    url: url_UntagResource_613442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagStream_613454 = ref object of OpenApiRestCall_612658
proc url_UntagStream_613456(protocol: Scheme; host: string; base: string;
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

proc validate_UntagStream_613455(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes one or more tags from a stream. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.</p> <p>In the request, you must provide the <code>StreamName</code> or <code>StreamARN</code>.</p>
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
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_UntagStream_613454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more tags from a stream. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.</p> <p>In the request, you must provide the <code>StreamName</code> or <code>StreamARN</code>.</p>
  ## 
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_UntagStream_613454; body: JsonNode): Recallable =
  ## untagStream
  ## <p>Removes one or more tags from a stream. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.</p> <p>In the request, you must provide the <code>StreamName</code> or <code>StreamARN</code>.</p>
  ##   body: JObject (required)
  var body_613467 = newJObject()
  if body != nil:
    body_613467 = body
  result = call_613466.call(nil, nil, nil, nil, body_613467)

var untagStream* = Call_UntagStream_613454(name: "untagStream",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/untagStream",
                                        validator: validate_UntagStream_613455,
                                        base: "/", url: url_UntagStream_613456,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataRetention_613468 = ref object of OpenApiRestCall_612658
proc url_UpdateDataRetention_613470(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataRetention_613469(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> Increases or decreases the stream's data retention period by the value that you specify. To indicate whether you want to increase or decrease the data retention period, specify the <code>Operation</code> parameter in the request body. In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p> <note> <p>The retention period that you specify replaces the current value.</p> </note> <p>This operation requires permission for the <code>KinesisVideo:UpdateDataRetention</code> action.</p> <p>Changing the data retention period affects the data in the stream as follows:</p> <ul> <li> <p>If the data retention period is increased, existing data is retained for the new retention period. For example, if the data retention period is increased from one hour to seven hours, all existing data is retained for seven hours.</p> </li> <li> <p>If the data retention period is decreased, existing data is retained for the new retention period. For example, if the data retention period is decreased from seven hours to one hour, all existing data is retained for one hour, and any data older than one hour is deleted immediately.</p> </li> </ul>
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
  var valid_613471 = header.getOrDefault("X-Amz-Signature")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Signature", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Content-Sha256", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Date")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Date", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Credential")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Credential", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Security-Token")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Security-Token", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Algorithm")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Algorithm", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-SignedHeaders", valid_613477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613479: Call_UpdateDataRetention_613468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Increases or decreases the stream's data retention period by the value that you specify. To indicate whether you want to increase or decrease the data retention period, specify the <code>Operation</code> parameter in the request body. In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p> <note> <p>The retention period that you specify replaces the current value.</p> </note> <p>This operation requires permission for the <code>KinesisVideo:UpdateDataRetention</code> action.</p> <p>Changing the data retention period affects the data in the stream as follows:</p> <ul> <li> <p>If the data retention period is increased, existing data is retained for the new retention period. For example, if the data retention period is increased from one hour to seven hours, all existing data is retained for seven hours.</p> </li> <li> <p>If the data retention period is decreased, existing data is retained for the new retention period. For example, if the data retention period is decreased from seven hours to one hour, all existing data is retained for one hour, and any data older than one hour is deleted immediately.</p> </li> </ul>
  ## 
  let valid = call_613479.validator(path, query, header, formData, body)
  let scheme = call_613479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613479.url(scheme.get, call_613479.host, call_613479.base,
                         call_613479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613479, url, valid)

proc call*(call_613480: Call_UpdateDataRetention_613468; body: JsonNode): Recallable =
  ## updateDataRetention
  ## <p> Increases or decreases the stream's data retention period by the value that you specify. To indicate whether you want to increase or decrease the data retention period, specify the <code>Operation</code> parameter in the request body. In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p> <note> <p>The retention period that you specify replaces the current value.</p> </note> <p>This operation requires permission for the <code>KinesisVideo:UpdateDataRetention</code> action.</p> <p>Changing the data retention period affects the data in the stream as follows:</p> <ul> <li> <p>If the data retention period is increased, existing data is retained for the new retention period. For example, if the data retention period is increased from one hour to seven hours, all existing data is retained for seven hours.</p> </li> <li> <p>If the data retention period is decreased, existing data is retained for the new retention period. For example, if the data retention period is decreased from seven hours to one hour, all existing data is retained for one hour, and any data older than one hour is deleted immediately.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613481 = newJObject()
  if body != nil:
    body_613481 = body
  result = call_613480.call(nil, nil, nil, nil, body_613481)

var updateDataRetention* = Call_UpdateDataRetention_613468(
    name: "updateDataRetention", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/updateDataRetention",
    validator: validate_UpdateDataRetention_613469, base: "/",
    url: url_UpdateDataRetention_613470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSignalingChannel_613482 = ref object of OpenApiRestCall_612658
proc url_UpdateSignalingChannel_613484(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSignalingChannel_613483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the existing signaling channel. This is an asynchronous operation and takes time to complete. </p> <p>If the <code>MessageTtlSeconds</code> value is updated (either increased or reduced), then it only applies to new messages sent via this channel after it's been updated. Existing messages are still expire as per the previous <code>MessageTtlSeconds</code> value.</p>
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
  var valid_613485 = header.getOrDefault("X-Amz-Signature")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Signature", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Content-Sha256", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Date")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Date", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Credential")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Credential", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Security-Token")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Security-Token", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Algorithm")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Algorithm", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-SignedHeaders", valid_613491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613493: Call_UpdateSignalingChannel_613482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the existing signaling channel. This is an asynchronous operation and takes time to complete. </p> <p>If the <code>MessageTtlSeconds</code> value is updated (either increased or reduced), then it only applies to new messages sent via this channel after it's been updated. Existing messages are still expire as per the previous <code>MessageTtlSeconds</code> value.</p>
  ## 
  let valid = call_613493.validator(path, query, header, formData, body)
  let scheme = call_613493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613493.url(scheme.get, call_613493.host, call_613493.base,
                         call_613493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613493, url, valid)

proc call*(call_613494: Call_UpdateSignalingChannel_613482; body: JsonNode): Recallable =
  ## updateSignalingChannel
  ## <p>Updates the existing signaling channel. This is an asynchronous operation and takes time to complete. </p> <p>If the <code>MessageTtlSeconds</code> value is updated (either increased or reduced), then it only applies to new messages sent via this channel after it's been updated. Existing messages are still expire as per the previous <code>MessageTtlSeconds</code> value.</p>
  ##   body: JObject (required)
  var body_613495 = newJObject()
  if body != nil:
    body_613495 = body
  result = call_613494.call(nil, nil, nil, nil, body_613495)

var updateSignalingChannel* = Call_UpdateSignalingChannel_613482(
    name: "updateSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/updateSignalingChannel",
    validator: validate_UpdateSignalingChannel_613483, base: "/",
    url: url_UpdateSignalingChannel_613484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStream_613496 = ref object of OpenApiRestCall_612658
proc url_UpdateStream_613498(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStream_613497(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates stream metadata, such as the device name and media type.</p> <p>You must provide the stream name or the Amazon Resource Name (ARN) of the stream.</p> <p>To make sure that you have the latest version of the stream before updating it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p> <code>UpdateStream</code> is an asynchronous operation, and takes time to complete.</p>
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
  var valid_613499 = header.getOrDefault("X-Amz-Signature")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Signature", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Content-Sha256", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Date")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Date", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Credential")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Credential", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Security-Token")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Security-Token", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Algorithm")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Algorithm", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-SignedHeaders", valid_613505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613507: Call_UpdateStream_613496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates stream metadata, such as the device name and media type.</p> <p>You must provide the stream name or the Amazon Resource Name (ARN) of the stream.</p> <p>To make sure that you have the latest version of the stream before updating it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p> <code>UpdateStream</code> is an asynchronous operation, and takes time to complete.</p>
  ## 
  let valid = call_613507.validator(path, query, header, formData, body)
  let scheme = call_613507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613507.url(scheme.get, call_613507.host, call_613507.base,
                         call_613507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613507, url, valid)

proc call*(call_613508: Call_UpdateStream_613496; body: JsonNode): Recallable =
  ## updateStream
  ## <p>Updates stream metadata, such as the device name and media type.</p> <p>You must provide the stream name or the Amazon Resource Name (ARN) of the stream.</p> <p>To make sure that you have the latest version of the stream before updating it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p> <code>UpdateStream</code> is an asynchronous operation, and takes time to complete.</p>
  ##   body: JObject (required)
  var body_613509 = newJObject()
  if body != nil:
    body_613509 = body
  result = call_613508.call(nil, nil, nil, nil, body_613509)

var updateStream* = Call_UpdateStream_613496(name: "updateStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/updateStream", validator: validate_UpdateStream_613497, base: "/",
    url: url_UpdateStream_613498, schemes: {Scheme.Https, Scheme.Http})
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
