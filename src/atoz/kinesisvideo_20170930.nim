
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CreateSignalingChannel_597727 = ref object of OpenApiRestCall_597389
proc url_CreateSignalingChannel_597729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSignalingChannel_597728(path: JsonNode; query: JsonNode;
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
  var valid_597841 = header.getOrDefault("X-Amz-Signature")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "X-Amz-Signature", valid_597841
  var valid_597842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "X-Amz-Content-Sha256", valid_597842
  var valid_597843 = header.getOrDefault("X-Amz-Date")
  valid_597843 = validateParameter(valid_597843, JString, required = false,
                                 default = nil)
  if valid_597843 != nil:
    section.add "X-Amz-Date", valid_597843
  var valid_597844 = header.getOrDefault("X-Amz-Credential")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-Credential", valid_597844
  var valid_597845 = header.getOrDefault("X-Amz-Security-Token")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "X-Amz-Security-Token", valid_597845
  var valid_597846 = header.getOrDefault("X-Amz-Algorithm")
  valid_597846 = validateParameter(valid_597846, JString, required = false,
                                 default = nil)
  if valid_597846 != nil:
    section.add "X-Amz-Algorithm", valid_597846
  var valid_597847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-SignedHeaders", valid_597847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597871: Call_CreateSignalingChannel_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a signaling channel. </p> <p> <code>CreateSignalingChannel</code> is an asynchronous operation.</p>
  ## 
  let valid = call_597871.validator(path, query, header, formData, body)
  let scheme = call_597871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597871.url(scheme.get, call_597871.host, call_597871.base,
                         call_597871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597871, url, valid)

proc call*(call_597942: Call_CreateSignalingChannel_597727; body: JsonNode): Recallable =
  ## createSignalingChannel
  ## <p>Creates a signaling channel. </p> <p> <code>CreateSignalingChannel</code> is an asynchronous operation.</p>
  ##   body: JObject (required)
  var body_597943 = newJObject()
  if body != nil:
    body_597943 = body
  result = call_597942.call(nil, nil, nil, nil, body_597943)

var createSignalingChannel* = Call_CreateSignalingChannel_597727(
    name: "createSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/createSignalingChannel",
    validator: validate_CreateSignalingChannel_597728, base: "/",
    url: url_CreateSignalingChannel_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStream_597982 = ref object of OpenApiRestCall_597389
proc url_CreateStream_597984(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStream_597983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597985 = header.getOrDefault("X-Amz-Signature")
  valid_597985 = validateParameter(valid_597985, JString, required = false,
                                 default = nil)
  if valid_597985 != nil:
    section.add "X-Amz-Signature", valid_597985
  var valid_597986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597986 = validateParameter(valid_597986, JString, required = false,
                                 default = nil)
  if valid_597986 != nil:
    section.add "X-Amz-Content-Sha256", valid_597986
  var valid_597987 = header.getOrDefault("X-Amz-Date")
  valid_597987 = validateParameter(valid_597987, JString, required = false,
                                 default = nil)
  if valid_597987 != nil:
    section.add "X-Amz-Date", valid_597987
  var valid_597988 = header.getOrDefault("X-Amz-Credential")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "X-Amz-Credential", valid_597988
  var valid_597989 = header.getOrDefault("X-Amz-Security-Token")
  valid_597989 = validateParameter(valid_597989, JString, required = false,
                                 default = nil)
  if valid_597989 != nil:
    section.add "X-Amz-Security-Token", valid_597989
  var valid_597990 = header.getOrDefault("X-Amz-Algorithm")
  valid_597990 = validateParameter(valid_597990, JString, required = false,
                                 default = nil)
  if valid_597990 != nil:
    section.add "X-Amz-Algorithm", valid_597990
  var valid_597991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597991 = validateParameter(valid_597991, JString, required = false,
                                 default = nil)
  if valid_597991 != nil:
    section.add "X-Amz-SignedHeaders", valid_597991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597993: Call_CreateStream_597982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Kinesis video stream. </p> <p>When you create a new stream, Kinesis Video Streams assigns it a version number. When you change the stream's metadata, Kinesis Video Streams updates the version. </p> <p> <code>CreateStream</code> is an asynchronous operation.</p> <p>For information about how the service works, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-it-works.html">How it Works</a>. </p> <p>You must have permissions for the <code>KinesisVideo:CreateStream</code> action.</p>
  ## 
  let valid = call_597993.validator(path, query, header, formData, body)
  let scheme = call_597993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597993.url(scheme.get, call_597993.host, call_597993.base,
                         call_597993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597993, url, valid)

proc call*(call_597994: Call_CreateStream_597982; body: JsonNode): Recallable =
  ## createStream
  ## <p>Creates a new Kinesis video stream. </p> <p>When you create a new stream, Kinesis Video Streams assigns it a version number. When you change the stream's metadata, Kinesis Video Streams updates the version. </p> <p> <code>CreateStream</code> is an asynchronous operation.</p> <p>For information about how the service works, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-it-works.html">How it Works</a>. </p> <p>You must have permissions for the <code>KinesisVideo:CreateStream</code> action.</p>
  ##   body: JObject (required)
  var body_597995 = newJObject()
  if body != nil:
    body_597995 = body
  result = call_597994.call(nil, nil, nil, nil, body_597995)

var createStream* = Call_CreateStream_597982(name: "createStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/createStream", validator: validate_CreateStream_597983, base: "/",
    url: url_CreateStream_597984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSignalingChannel_597996 = ref object of OpenApiRestCall_597389
proc url_DeleteSignalingChannel_597998(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSignalingChannel_597997(path: JsonNode; query: JsonNode;
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
  var valid_597999 = header.getOrDefault("X-Amz-Signature")
  valid_597999 = validateParameter(valid_597999, JString, required = false,
                                 default = nil)
  if valid_597999 != nil:
    section.add "X-Amz-Signature", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Content-Sha256", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Date")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Date", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Credential")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Credential", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Security-Token")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Security-Token", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Algorithm")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Algorithm", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-SignedHeaders", valid_598005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598007: Call_DeleteSignalingChannel_597996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified signaling channel. <code>DeleteSignalingChannel</code> is an asynchronous operation. If you don't specify the channel's current version, the most recent version is deleted.
  ## 
  let valid = call_598007.validator(path, query, header, formData, body)
  let scheme = call_598007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598007.url(scheme.get, call_598007.host, call_598007.base,
                         call_598007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598007, url, valid)

proc call*(call_598008: Call_DeleteSignalingChannel_597996; body: JsonNode): Recallable =
  ## deleteSignalingChannel
  ## Deletes a specified signaling channel. <code>DeleteSignalingChannel</code> is an asynchronous operation. If you don't specify the channel's current version, the most recent version is deleted.
  ##   body: JObject (required)
  var body_598009 = newJObject()
  if body != nil:
    body_598009 = body
  result = call_598008.call(nil, nil, nil, nil, body_598009)

var deleteSignalingChannel* = Call_DeleteSignalingChannel_597996(
    name: "deleteSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/deleteSignalingChannel",
    validator: validate_DeleteSignalingChannel_597997, base: "/",
    url: url_DeleteSignalingChannel_597998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStream_598010 = ref object of OpenApiRestCall_597389
proc url_DeleteStream_598012(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStream_598011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598013 = header.getOrDefault("X-Amz-Signature")
  valid_598013 = validateParameter(valid_598013, JString, required = false,
                                 default = nil)
  if valid_598013 != nil:
    section.add "X-Amz-Signature", valid_598013
  var valid_598014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598014 = validateParameter(valid_598014, JString, required = false,
                                 default = nil)
  if valid_598014 != nil:
    section.add "X-Amz-Content-Sha256", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Date")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Date", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Credential")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Credential", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Security-Token")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Security-Token", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Algorithm")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Algorithm", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-SignedHeaders", valid_598019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598021: Call_DeleteStream_598010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Kinesis video stream and the data contained in the stream. </p> <p>This method marks the stream for deletion, and makes the data in the stream inaccessible immediately.</p> <p> </p> <p> To ensure that you have the latest version of the stream before deleting it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p>This operation requires permission for the <code>KinesisVideo:DeleteStream</code> action.</p>
  ## 
  let valid = call_598021.validator(path, query, header, formData, body)
  let scheme = call_598021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598021.url(scheme.get, call_598021.host, call_598021.base,
                         call_598021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598021, url, valid)

proc call*(call_598022: Call_DeleteStream_598010; body: JsonNode): Recallable =
  ## deleteStream
  ## <p>Deletes a Kinesis video stream and the data contained in the stream. </p> <p>This method marks the stream for deletion, and makes the data in the stream inaccessible immediately.</p> <p> </p> <p> To ensure that you have the latest version of the stream before deleting it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p>This operation requires permission for the <code>KinesisVideo:DeleteStream</code> action.</p>
  ##   body: JObject (required)
  var body_598023 = newJObject()
  if body != nil:
    body_598023 = body
  result = call_598022.call(nil, nil, nil, nil, body_598023)

var deleteStream* = Call_DeleteStream_598010(name: "deleteStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/deleteStream", validator: validate_DeleteStream_598011, base: "/",
    url: url_DeleteStream_598012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSignalingChannel_598024 = ref object of OpenApiRestCall_597389
proc url_DescribeSignalingChannel_598026(protocol: Scheme; host: string;
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

proc validate_DescribeSignalingChannel_598025(path: JsonNode; query: JsonNode;
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
  var valid_598027 = header.getOrDefault("X-Amz-Signature")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Signature", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-Content-Sha256", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-Date")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-Date", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Credential")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Credential", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Security-Token")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Security-Token", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Algorithm")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Algorithm", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-SignedHeaders", valid_598033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598035: Call_DescribeSignalingChannel_598024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the most current information about the signaling channel. You must specify either the name or the ARN of the channel that you want to describe.
  ## 
  let valid = call_598035.validator(path, query, header, formData, body)
  let scheme = call_598035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598035.url(scheme.get, call_598035.host, call_598035.base,
                         call_598035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598035, url, valid)

proc call*(call_598036: Call_DescribeSignalingChannel_598024; body: JsonNode): Recallable =
  ## describeSignalingChannel
  ## Returns the most current information about the signaling channel. You must specify either the name or the ARN of the channel that you want to describe.
  ##   body: JObject (required)
  var body_598037 = newJObject()
  if body != nil:
    body_598037 = body
  result = call_598036.call(nil, nil, nil, nil, body_598037)

var describeSignalingChannel* = Call_DescribeSignalingChannel_598024(
    name: "describeSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/describeSignalingChannel",
    validator: validate_DescribeSignalingChannel_598025, base: "/",
    url: url_DescribeSignalingChannel_598026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStream_598038 = ref object of OpenApiRestCall_597389
proc url_DescribeStream_598040(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeStream_598039(path: JsonNode; query: JsonNode;
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
  var valid_598041 = header.getOrDefault("X-Amz-Signature")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Signature", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-Content-Sha256", valid_598042
  var valid_598043 = header.getOrDefault("X-Amz-Date")
  valid_598043 = validateParameter(valid_598043, JString, required = false,
                                 default = nil)
  if valid_598043 != nil:
    section.add "X-Amz-Date", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-Credential")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Credential", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Security-Token")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Security-Token", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Algorithm")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Algorithm", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-SignedHeaders", valid_598047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598049: Call_DescribeStream_598038; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the most current information about the specified stream. You must specify either the <code>StreamName</code> or the <code>StreamARN</code>. 
  ## 
  let valid = call_598049.validator(path, query, header, formData, body)
  let scheme = call_598049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598049.url(scheme.get, call_598049.host, call_598049.base,
                         call_598049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598049, url, valid)

proc call*(call_598050: Call_DescribeStream_598038; body: JsonNode): Recallable =
  ## describeStream
  ## Returns the most current information about the specified stream. You must specify either the <code>StreamName</code> or the <code>StreamARN</code>. 
  ##   body: JObject (required)
  var body_598051 = newJObject()
  if body != nil:
    body_598051 = body
  result = call_598050.call(nil, nil, nil, nil, body_598051)

var describeStream* = Call_DescribeStream_598038(name: "describeStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/describeStream", validator: validate_DescribeStream_598039, base: "/",
    url: url_DescribeStream_598040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataEndpoint_598052 = ref object of OpenApiRestCall_597389
proc url_GetDataEndpoint_598054(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataEndpoint_598053(path: JsonNode; query: JsonNode;
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
  var valid_598055 = header.getOrDefault("X-Amz-Signature")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Signature", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-Content-Sha256", valid_598056
  var valid_598057 = header.getOrDefault("X-Amz-Date")
  valid_598057 = validateParameter(valid_598057, JString, required = false,
                                 default = nil)
  if valid_598057 != nil:
    section.add "X-Amz-Date", valid_598057
  var valid_598058 = header.getOrDefault("X-Amz-Credential")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-Credential", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-Security-Token")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-Security-Token", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Algorithm")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Algorithm", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-SignedHeaders", valid_598061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598063: Call_GetDataEndpoint_598052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets an endpoint for a specified stream for either reading or writing. Use this endpoint in your application to read from the specified stream (using the <code>GetMedia</code> or <code>GetMediaForFragmentList</code> operations) or write to it (using the <code>PutMedia</code> operation). </p> <note> <p>The returned endpoint does not have the API name appended. The client needs to add the API name to the returned endpoint.</p> </note> <p>In the request, specify the stream either by <code>StreamName</code> or <code>StreamARN</code>.</p>
  ## 
  let valid = call_598063.validator(path, query, header, formData, body)
  let scheme = call_598063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598063.url(scheme.get, call_598063.host, call_598063.base,
                         call_598063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598063, url, valid)

proc call*(call_598064: Call_GetDataEndpoint_598052; body: JsonNode): Recallable =
  ## getDataEndpoint
  ## <p>Gets an endpoint for a specified stream for either reading or writing. Use this endpoint in your application to read from the specified stream (using the <code>GetMedia</code> or <code>GetMediaForFragmentList</code> operations) or write to it (using the <code>PutMedia</code> operation). </p> <note> <p>The returned endpoint does not have the API name appended. The client needs to add the API name to the returned endpoint.</p> </note> <p>In the request, specify the stream either by <code>StreamName</code> or <code>StreamARN</code>.</p>
  ##   body: JObject (required)
  var body_598065 = newJObject()
  if body != nil:
    body_598065 = body
  result = call_598064.call(nil, nil, nil, nil, body_598065)

var getDataEndpoint* = Call_GetDataEndpoint_598052(name: "getDataEndpoint",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/getDataEndpoint", validator: validate_GetDataEndpoint_598053,
    base: "/", url: url_GetDataEndpoint_598054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSignalingChannelEndpoint_598066 = ref object of OpenApiRestCall_597389
proc url_GetSignalingChannelEndpoint_598068(protocol: Scheme; host: string;
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

proc validate_GetSignalingChannelEndpoint_598067(path: JsonNode; query: JsonNode;
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
  var valid_598069 = header.getOrDefault("X-Amz-Signature")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Signature", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Content-Sha256", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Date")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Date", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Credential")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Credential", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-Security-Token")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Security-Token", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Algorithm")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Algorithm", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-SignedHeaders", valid_598075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598077: Call_GetSignalingChannelEndpoint_598066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides an endpoint for the specified signaling channel to send and receive messages. This API uses the <code>SingleMasterChannelEndpointConfiguration</code> input parameter, which consists of the <code>Protocols</code> and <code>Role</code> properties.</p> <p> <code>Protocols</code> is used to determine the communication mechanism. For example, specifying <code>WSS</code> as the protocol, results in this API producing a secure websocket endpoint, and specifying <code>HTTPS</code> as the protocol, results in this API generating an HTTPS endpoint. </p> <p> <code>Role</code> determines the messaging permissions. A <code>MASTER</code> role results in this API generating an endpoint that a client can use to communicate with any of the viewers on the channel. A <code>VIEWER</code> role results in this API generating an endpoint that a client can use to communicate only with a <code>MASTER</code>. </p>
  ## 
  let valid = call_598077.validator(path, query, header, formData, body)
  let scheme = call_598077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598077.url(scheme.get, call_598077.host, call_598077.base,
                         call_598077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598077, url, valid)

proc call*(call_598078: Call_GetSignalingChannelEndpoint_598066; body: JsonNode): Recallable =
  ## getSignalingChannelEndpoint
  ## <p>Provides an endpoint for the specified signaling channel to send and receive messages. This API uses the <code>SingleMasterChannelEndpointConfiguration</code> input parameter, which consists of the <code>Protocols</code> and <code>Role</code> properties.</p> <p> <code>Protocols</code> is used to determine the communication mechanism. For example, specifying <code>WSS</code> as the protocol, results in this API producing a secure websocket endpoint, and specifying <code>HTTPS</code> as the protocol, results in this API generating an HTTPS endpoint. </p> <p> <code>Role</code> determines the messaging permissions. A <code>MASTER</code> role results in this API generating an endpoint that a client can use to communicate with any of the viewers on the channel. A <code>VIEWER</code> role results in this API generating an endpoint that a client can use to communicate only with a <code>MASTER</code>. </p>
  ##   body: JObject (required)
  var body_598079 = newJObject()
  if body != nil:
    body_598079 = body
  result = call_598078.call(nil, nil, nil, nil, body_598079)

var getSignalingChannelEndpoint* = Call_GetSignalingChannelEndpoint_598066(
    name: "getSignalingChannelEndpoint", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/getSignalingChannelEndpoint",
    validator: validate_GetSignalingChannelEndpoint_598067, base: "/",
    url: url_GetSignalingChannelEndpoint_598068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSignalingChannels_598080 = ref object of OpenApiRestCall_597389
proc url_ListSignalingChannels_598082(protocol: Scheme; host: string; base: string;
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

proc validate_ListSignalingChannels_598081(path: JsonNode; query: JsonNode;
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
  var valid_598083 = query.getOrDefault("MaxResults")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "MaxResults", valid_598083
  var valid_598084 = query.getOrDefault("NextToken")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "NextToken", valid_598084
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
  var valid_598085 = header.getOrDefault("X-Amz-Signature")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Signature", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Content-Sha256", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Date")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Date", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-Credential")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-Credential", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-Security-Token")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-Security-Token", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Algorithm")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Algorithm", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-SignedHeaders", valid_598091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598093: Call_ListSignalingChannels_598080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ChannelInfo</code> objects. Each object describes a signaling channel. To retrieve only those channels that satisfy a specific condition, you can specify a <code>ChannelNameCondition</code>.
  ## 
  let valid = call_598093.validator(path, query, header, formData, body)
  let scheme = call_598093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598093.url(scheme.get, call_598093.host, call_598093.base,
                         call_598093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598093, url, valid)

proc call*(call_598094: Call_ListSignalingChannels_598080; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSignalingChannels
  ## Returns an array of <code>ChannelInfo</code> objects. Each object describes a signaling channel. To retrieve only those channels that satisfy a specific condition, you can specify a <code>ChannelNameCondition</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598095 = newJObject()
  var body_598096 = newJObject()
  add(query_598095, "MaxResults", newJString(MaxResults))
  add(query_598095, "NextToken", newJString(NextToken))
  if body != nil:
    body_598096 = body
  result = call_598094.call(nil, query_598095, nil, nil, body_598096)

var listSignalingChannels* = Call_ListSignalingChannels_598080(
    name: "listSignalingChannels", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/listSignalingChannels",
    validator: validate_ListSignalingChannels_598081, base: "/",
    url: url_ListSignalingChannels_598082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreams_598098 = ref object of OpenApiRestCall_597389
proc url_ListStreams_598100(protocol: Scheme; host: string; base: string;
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

proc validate_ListStreams_598099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598101 = query.getOrDefault("MaxResults")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "MaxResults", valid_598101
  var valid_598102 = query.getOrDefault("NextToken")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "NextToken", valid_598102
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
  var valid_598103 = header.getOrDefault("X-Amz-Signature")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Signature", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Content-Sha256", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Date")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Date", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Credential")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Credential", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Security-Token")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Security-Token", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Algorithm")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Algorithm", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-SignedHeaders", valid_598109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598111: Call_ListStreams_598098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>StreamInfo</code> objects. Each object describes a stream. To retrieve only streams that satisfy a specific condition, you can specify a <code>StreamNameCondition</code>. 
  ## 
  let valid = call_598111.validator(path, query, header, formData, body)
  let scheme = call_598111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598111.url(scheme.get, call_598111.host, call_598111.base,
                         call_598111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598111, url, valid)

proc call*(call_598112: Call_ListStreams_598098; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreams
  ## Returns an array of <code>StreamInfo</code> objects. Each object describes a stream. To retrieve only streams that satisfy a specific condition, you can specify a <code>StreamNameCondition</code>. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598113 = newJObject()
  var body_598114 = newJObject()
  add(query_598113, "MaxResults", newJString(MaxResults))
  add(query_598113, "NextToken", newJString(NextToken))
  if body != nil:
    body_598114 = body
  result = call_598112.call(nil, query_598113, nil, nil, body_598114)

var listStreams* = Call_ListStreams_598098(name: "listStreams",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/listStreams",
                                        validator: validate_ListStreams_598099,
                                        base: "/", url: url_ListStreams_598100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598115 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598117(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598116(path: JsonNode; query: JsonNode;
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
  var valid_598118 = header.getOrDefault("X-Amz-Signature")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Signature", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Content-Sha256", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Date")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Date", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Credential")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Credential", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Security-Token")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Security-Token", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Algorithm")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Algorithm", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-SignedHeaders", valid_598124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598126: Call_ListTagsForResource_598115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with the specified signaling channel.
  ## 
  let valid = call_598126.validator(path, query, header, formData, body)
  let scheme = call_598126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598126.url(scheme.get, call_598126.host, call_598126.base,
                         call_598126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598126, url, valid)

proc call*(call_598127: Call_ListTagsForResource_598115; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with the specified signaling channel.
  ##   body: JObject (required)
  var body_598128 = newJObject()
  if body != nil:
    body_598128 = body
  result = call_598127.call(nil, nil, nil, nil, body_598128)

var listTagsForResource* = Call_ListTagsForResource_598115(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/ListTagsForResource",
    validator: validate_ListTagsForResource_598116, base: "/",
    url: url_ListTagsForResource_598117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForStream_598129 = ref object of OpenApiRestCall_597389
proc url_ListTagsForStream_598131(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForStream_598130(path: JsonNode; query: JsonNode;
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
  var valid_598132 = header.getOrDefault("X-Amz-Signature")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Signature", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-Content-Sha256", valid_598133
  var valid_598134 = header.getOrDefault("X-Amz-Date")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-Date", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Credential")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Credential", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Security-Token")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Security-Token", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Algorithm")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Algorithm", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-SignedHeaders", valid_598138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598140: Call_ListTagsForStream_598129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tags associated with the specified stream.</p> <p>In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p>
  ## 
  let valid = call_598140.validator(path, query, header, formData, body)
  let scheme = call_598140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598140.url(scheme.get, call_598140.host, call_598140.base,
                         call_598140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598140, url, valid)

proc call*(call_598141: Call_ListTagsForStream_598129; body: JsonNode): Recallable =
  ## listTagsForStream
  ## <p>Returns a list of tags associated with the specified stream.</p> <p>In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p>
  ##   body: JObject (required)
  var body_598142 = newJObject()
  if body != nil:
    body_598142 = body
  result = call_598141.call(nil, nil, nil, nil, body_598142)

var listTagsForStream* = Call_ListTagsForStream_598129(name: "listTagsForStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/listTagsForStream", validator: validate_ListTagsForStream_598130,
    base: "/", url: url_ListTagsForStream_598131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598143 = ref object of OpenApiRestCall_597389
proc url_TagResource_598145(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598144(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598146 = header.getOrDefault("X-Amz-Signature")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Signature", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Content-Sha256", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Date")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Date", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-Credential")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-Credential", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Security-Token")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Security-Token", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Algorithm")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Algorithm", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-SignedHeaders", valid_598152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598154: Call_TagResource_598143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a signaling channel. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.
  ## 
  let valid = call_598154.validator(path, query, header, formData, body)
  let scheme = call_598154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598154.url(scheme.get, call_598154.host, call_598154.base,
                         call_598154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598154, url, valid)

proc call*(call_598155: Call_TagResource_598143; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a signaling channel. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.
  ##   body: JObject (required)
  var body_598156 = newJObject()
  if body != nil:
    body_598156 = body
  result = call_598155.call(nil, nil, nil, nil, body_598156)

var tagResource* = Call_TagResource_598143(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/TagResource",
                                        validator: validate_TagResource_598144,
                                        base: "/", url: url_TagResource_598145,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagStream_598157 = ref object of OpenApiRestCall_597389
proc url_TagStream_598159(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_TagStream_598158(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598160 = header.getOrDefault("X-Amz-Signature")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Signature", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Content-Sha256", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Date")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Date", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-Credential")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Credential", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-Security-Token")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-Security-Token", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Algorithm")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Algorithm", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-SignedHeaders", valid_598166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598168: Call_TagStream_598157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a stream. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>You must provide either the <code>StreamName</code> or the <code>StreamARN</code>.</p> <p>This operation requires permission for the <code>KinesisVideo:TagStream</code> action.</p> <p>Kinesis video streams support up to 50 tags.</p>
  ## 
  let valid = call_598168.validator(path, query, header, formData, body)
  let scheme = call_598168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598168.url(scheme.get, call_598168.host, call_598168.base,
                         call_598168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598168, url, valid)

proc call*(call_598169: Call_TagStream_598157; body: JsonNode): Recallable =
  ## tagStream
  ## <p>Adds one or more tags to a stream. A <i>tag</i> is a key-value pair (the value is optional) that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>You must provide either the <code>StreamName</code> or the <code>StreamARN</code>.</p> <p>This operation requires permission for the <code>KinesisVideo:TagStream</code> action.</p> <p>Kinesis video streams support up to 50 tags.</p>
  ##   body: JObject (required)
  var body_598170 = newJObject()
  if body != nil:
    body_598170 = body
  result = call_598169.call(nil, nil, nil, nil, body_598170)

var tagStream* = Call_TagStream_598157(name: "tagStream", meth: HttpMethod.HttpPost,
                                    host: "kinesisvideo.amazonaws.com",
                                    route: "/tagStream",
                                    validator: validate_TagStream_598158,
                                    base: "/", url: url_TagStream_598159,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598171 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598173(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598174 = header.getOrDefault("X-Amz-Signature")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Signature", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Content-Sha256", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Date")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Date", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Credential")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Credential", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Security-Token")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Security-Token", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Algorithm")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Algorithm", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-SignedHeaders", valid_598180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598182: Call_UntagResource_598171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a signaling channel. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.
  ## 
  let valid = call_598182.validator(path, query, header, formData, body)
  let scheme = call_598182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598182.url(scheme.get, call_598182.host, call_598182.base,
                         call_598182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598182, url, valid)

proc call*(call_598183: Call_UntagResource_598171; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a signaling channel. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.
  ##   body: JObject (required)
  var body_598184 = newJObject()
  if body != nil:
    body_598184 = body
  result = call_598183.call(nil, nil, nil, nil, body_598184)

var untagResource* = Call_UntagResource_598171(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/UntagResource", validator: validate_UntagResource_598172, base: "/",
    url: url_UntagResource_598173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagStream_598185 = ref object of OpenApiRestCall_597389
proc url_UntagStream_598187(protocol: Scheme; host: string; base: string;
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

proc validate_UntagStream_598186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598188 = header.getOrDefault("X-Amz-Signature")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "X-Amz-Signature", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Content-Sha256", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Date")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Date", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Credential")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Credential", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Security-Token")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Security-Token", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Algorithm")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Algorithm", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-SignedHeaders", valid_598194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598196: Call_UntagStream_598185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more tags from a stream. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.</p> <p>In the request, you must provide the <code>StreamName</code> or <code>StreamARN</code>.</p>
  ## 
  let valid = call_598196.validator(path, query, header, formData, body)
  let scheme = call_598196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598196.url(scheme.get, call_598196.host, call_598196.base,
                         call_598196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598196, url, valid)

proc call*(call_598197: Call_UntagStream_598185; body: JsonNode): Recallable =
  ## untagStream
  ## <p>Removes one or more tags from a stream. In the request, specify only a tag key or keys; don't specify the value. If you specify a tag key that does not exist, it's ignored.</p> <p>In the request, you must provide the <code>StreamName</code> or <code>StreamARN</code>.</p>
  ##   body: JObject (required)
  var body_598198 = newJObject()
  if body != nil:
    body_598198 = body
  result = call_598197.call(nil, nil, nil, nil, body_598198)

var untagStream* = Call_UntagStream_598185(name: "untagStream",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisvideo.amazonaws.com",
                                        route: "/untagStream",
                                        validator: validate_UntagStream_598186,
                                        base: "/", url: url_UntagStream_598187,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataRetention_598199 = ref object of OpenApiRestCall_597389
proc url_UpdateDataRetention_598201(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataRetention_598200(path: JsonNode; query: JsonNode;
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
  var valid_598202 = header.getOrDefault("X-Amz-Signature")
  valid_598202 = validateParameter(valid_598202, JString, required = false,
                                 default = nil)
  if valid_598202 != nil:
    section.add "X-Amz-Signature", valid_598202
  var valid_598203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "X-Amz-Content-Sha256", valid_598203
  var valid_598204 = header.getOrDefault("X-Amz-Date")
  valid_598204 = validateParameter(valid_598204, JString, required = false,
                                 default = nil)
  if valid_598204 != nil:
    section.add "X-Amz-Date", valid_598204
  var valid_598205 = header.getOrDefault("X-Amz-Credential")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Credential", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Security-Token")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Security-Token", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Algorithm")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Algorithm", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-SignedHeaders", valid_598208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598210: Call_UpdateDataRetention_598199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Increases or decreases the stream's data retention period by the value that you specify. To indicate whether you want to increase or decrease the data retention period, specify the <code>Operation</code> parameter in the request body. In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p> <note> <p>The retention period that you specify replaces the current value.</p> </note> <p>This operation requires permission for the <code>KinesisVideo:UpdateDataRetention</code> action.</p> <p>Changing the data retention period affects the data in the stream as follows:</p> <ul> <li> <p>If the data retention period is increased, existing data is retained for the new retention period. For example, if the data retention period is increased from one hour to seven hours, all existing data is retained for seven hours.</p> </li> <li> <p>If the data retention period is decreased, existing data is retained for the new retention period. For example, if the data retention period is decreased from seven hours to one hour, all existing data is retained for one hour, and any data older than one hour is deleted immediately.</p> </li> </ul>
  ## 
  let valid = call_598210.validator(path, query, header, formData, body)
  let scheme = call_598210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598210.url(scheme.get, call_598210.host, call_598210.base,
                         call_598210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598210, url, valid)

proc call*(call_598211: Call_UpdateDataRetention_598199; body: JsonNode): Recallable =
  ## updateDataRetention
  ## <p> Increases or decreases the stream's data retention period by the value that you specify. To indicate whether you want to increase or decrease the data retention period, specify the <code>Operation</code> parameter in the request body. In the request, you must specify either the <code>StreamName</code> or the <code>StreamARN</code>. </p> <note> <p>The retention period that you specify replaces the current value.</p> </note> <p>This operation requires permission for the <code>KinesisVideo:UpdateDataRetention</code> action.</p> <p>Changing the data retention period affects the data in the stream as follows:</p> <ul> <li> <p>If the data retention period is increased, existing data is retained for the new retention period. For example, if the data retention period is increased from one hour to seven hours, all existing data is retained for seven hours.</p> </li> <li> <p>If the data retention period is decreased, existing data is retained for the new retention period. For example, if the data retention period is decreased from seven hours to one hour, all existing data is retained for one hour, and any data older than one hour is deleted immediately.</p> </li> </ul>
  ##   body: JObject (required)
  var body_598212 = newJObject()
  if body != nil:
    body_598212 = body
  result = call_598211.call(nil, nil, nil, nil, body_598212)

var updateDataRetention* = Call_UpdateDataRetention_598199(
    name: "updateDataRetention", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/updateDataRetention",
    validator: validate_UpdateDataRetention_598200, base: "/",
    url: url_UpdateDataRetention_598201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSignalingChannel_598213 = ref object of OpenApiRestCall_597389
proc url_UpdateSignalingChannel_598215(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSignalingChannel_598214(path: JsonNode; query: JsonNode;
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
  var valid_598216 = header.getOrDefault("X-Amz-Signature")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-Signature", valid_598216
  var valid_598217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598217 = validateParameter(valid_598217, JString, required = false,
                                 default = nil)
  if valid_598217 != nil:
    section.add "X-Amz-Content-Sha256", valid_598217
  var valid_598218 = header.getOrDefault("X-Amz-Date")
  valid_598218 = validateParameter(valid_598218, JString, required = false,
                                 default = nil)
  if valid_598218 != nil:
    section.add "X-Amz-Date", valid_598218
  var valid_598219 = header.getOrDefault("X-Amz-Credential")
  valid_598219 = validateParameter(valid_598219, JString, required = false,
                                 default = nil)
  if valid_598219 != nil:
    section.add "X-Amz-Credential", valid_598219
  var valid_598220 = header.getOrDefault("X-Amz-Security-Token")
  valid_598220 = validateParameter(valid_598220, JString, required = false,
                                 default = nil)
  if valid_598220 != nil:
    section.add "X-Amz-Security-Token", valid_598220
  var valid_598221 = header.getOrDefault("X-Amz-Algorithm")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Algorithm", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-SignedHeaders", valid_598222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598224: Call_UpdateSignalingChannel_598213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the existing signaling channel. This is an asynchronous operation and takes time to complete. </p> <p>If the <code>MessageTtlSeconds</code> value is updated (either increased or reduced), then it only applies to new messages sent via this channel after it's been updated. Existing messages are still expire as per the previous <code>MessageTtlSeconds</code> value.</p>
  ## 
  let valid = call_598224.validator(path, query, header, formData, body)
  let scheme = call_598224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598224.url(scheme.get, call_598224.host, call_598224.base,
                         call_598224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598224, url, valid)

proc call*(call_598225: Call_UpdateSignalingChannel_598213; body: JsonNode): Recallable =
  ## updateSignalingChannel
  ## <p>Updates the existing signaling channel. This is an asynchronous operation and takes time to complete. </p> <p>If the <code>MessageTtlSeconds</code> value is updated (either increased or reduced), then it only applies to new messages sent via this channel after it's been updated. Existing messages are still expire as per the previous <code>MessageTtlSeconds</code> value.</p>
  ##   body: JObject (required)
  var body_598226 = newJObject()
  if body != nil:
    body_598226 = body
  result = call_598225.call(nil, nil, nil, nil, body_598226)

var updateSignalingChannel* = Call_UpdateSignalingChannel_598213(
    name: "updateSignalingChannel", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/updateSignalingChannel",
    validator: validate_UpdateSignalingChannel_598214, base: "/",
    url: url_UpdateSignalingChannel_598215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStream_598227 = ref object of OpenApiRestCall_597389
proc url_UpdateStream_598229(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStream_598228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598230 = header.getOrDefault("X-Amz-Signature")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Signature", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-Content-Sha256", valid_598231
  var valid_598232 = header.getOrDefault("X-Amz-Date")
  valid_598232 = validateParameter(valid_598232, JString, required = false,
                                 default = nil)
  if valid_598232 != nil:
    section.add "X-Amz-Date", valid_598232
  var valid_598233 = header.getOrDefault("X-Amz-Credential")
  valid_598233 = validateParameter(valid_598233, JString, required = false,
                                 default = nil)
  if valid_598233 != nil:
    section.add "X-Amz-Credential", valid_598233
  var valid_598234 = header.getOrDefault("X-Amz-Security-Token")
  valid_598234 = validateParameter(valid_598234, JString, required = false,
                                 default = nil)
  if valid_598234 != nil:
    section.add "X-Amz-Security-Token", valid_598234
  var valid_598235 = header.getOrDefault("X-Amz-Algorithm")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-Algorithm", valid_598235
  var valid_598236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-SignedHeaders", valid_598236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598238: Call_UpdateStream_598227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates stream metadata, such as the device name and media type.</p> <p>You must provide the stream name or the Amazon Resource Name (ARN) of the stream.</p> <p>To make sure that you have the latest version of the stream before updating it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p> <code>UpdateStream</code> is an asynchronous operation, and takes time to complete.</p>
  ## 
  let valid = call_598238.validator(path, query, header, formData, body)
  let scheme = call_598238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598238.url(scheme.get, call_598238.host, call_598238.base,
                         call_598238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598238, url, valid)

proc call*(call_598239: Call_UpdateStream_598227; body: JsonNode): Recallable =
  ## updateStream
  ## <p>Updates stream metadata, such as the device name and media type.</p> <p>You must provide the stream name or the Amazon Resource Name (ARN) of the stream.</p> <p>To make sure that you have the latest version of the stream before updating it, you can specify the stream version. Kinesis Video Streams assigns a version to each stream. When you update a stream, Kinesis Video Streams assigns a new version number. To get the latest stream version, use the <code>DescribeStream</code> API. </p> <p> <code>UpdateStream</code> is an asynchronous operation, and takes time to complete.</p>
  ##   body: JObject (required)
  var body_598240 = newJObject()
  if body != nil:
    body_598240 = body
  result = call_598239.call(nil, nil, nil, nil, body_598240)

var updateStream* = Call_UpdateStream_598227(name: "updateStream",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/updateStream", validator: validate_UpdateStream_598228, base: "/",
    url: url_UpdateStream_598229, schemes: {Scheme.Https, Scheme.Http})
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
