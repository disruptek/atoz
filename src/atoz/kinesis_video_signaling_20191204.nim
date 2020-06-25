
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Video Signaling Channels
## version: 2019-12-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Kinesis Video Streams Signaling Service is a intermediate service that establishes a communication channel for discovering peers, transmitting offers and answers in order to establish peer-to-peer connection in webRTC technology.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kinesisvideo/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServiceName = "kinesis-video-signaling"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetIceServerConfig_21625770 = ref object of OpenApiRestCall_21625426
proc url_GetIceServerConfig_21625772(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIceServerConfig_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets the Interactive Connectivity Establishment (ICE) server configuration information, including URIs, username, and password which can be used to configure the WebRTC connection. The ICE component uses this configuration information to setup the WebRTC connection, including authenticating with the Traversal Using Relays around NAT (TURN) relay server. </p> <p>TURN is a protocol that is used to improve the connectivity of peer-to-peer applications. By providing a cloud-based relay service, TURN ensures that a connection can be established even when one or more peers are incapable of a direct peer-to-peer connection. For more information, see <a href="https://tools.ietf.org/html/draft-uberti-rtcweb-turn-rest-00">A REST API For Access To TURN Services</a>.</p> <p> You can invoke this API to establish a fallback mechanism in case either of the peers is unable to establish a direct peer-to-peer connection over a signaling channel. You must specify either a signaling channel ARN or the client ID in order to invoke this API.</p>
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
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625875
  var valid_21625876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625876 = validateParameter(valid_21625876, JString, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Algorithm", valid_21625876
  var valid_21625877 = header.getOrDefault("X-Amz-Signature")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "X-Amz-Signature", valid_21625877
  var valid_21625878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625878 = validateParameter(valid_21625878, JString, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625878
  var valid_21625879 = header.getOrDefault("X-Amz-Credential")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Credential", valid_21625879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625905: Call_GetIceServerConfig_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the Interactive Connectivity Establishment (ICE) server configuration information, including URIs, username, and password which can be used to configure the WebRTC connection. The ICE component uses this configuration information to setup the WebRTC connection, including authenticating with the Traversal Using Relays around NAT (TURN) relay server. </p> <p>TURN is a protocol that is used to improve the connectivity of peer-to-peer applications. By providing a cloud-based relay service, TURN ensures that a connection can be established even when one or more peers are incapable of a direct peer-to-peer connection. For more information, see <a href="https://tools.ietf.org/html/draft-uberti-rtcweb-turn-rest-00">A REST API For Access To TURN Services</a>.</p> <p> You can invoke this API to establish a fallback mechanism in case either of the peers is unable to establish a direct peer-to-peer connection over a signaling channel. You must specify either a signaling channel ARN or the client ID in order to invoke this API.</p>
  ## 
  let valid = call_21625905.validator(path, query, header, formData, body, _)
  let scheme = call_21625905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625905.makeUrl(scheme.get, call_21625905.host, call_21625905.base,
                               call_21625905.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625905, uri, valid, _)

proc call*(call_21625968: Call_GetIceServerConfig_21625770; body: JsonNode): Recallable =
  ## getIceServerConfig
  ## <p>Gets the Interactive Connectivity Establishment (ICE) server configuration information, including URIs, username, and password which can be used to configure the WebRTC connection. The ICE component uses this configuration information to setup the WebRTC connection, including authenticating with the Traversal Using Relays around NAT (TURN) relay server. </p> <p>TURN is a protocol that is used to improve the connectivity of peer-to-peer applications. By providing a cloud-based relay service, TURN ensures that a connection can be established even when one or more peers are incapable of a direct peer-to-peer connection. For more information, see <a href="https://tools.ietf.org/html/draft-uberti-rtcweb-turn-rest-00">A REST API For Access To TURN Services</a>.</p> <p> You can invoke this API to establish a fallback mechanism in case either of the peers is unable to establish a direct peer-to-peer connection over a signaling channel. You must specify either a signaling channel ARN or the client ID in order to invoke this API.</p>
  ##   body: JObject (required)
  var body_21625969 = newJObject()
  if body != nil:
    body_21625969 = body
  result = call_21625968.call(nil, nil, nil, nil, body_21625969)

var getIceServerConfig* = Call_GetIceServerConfig_21625770(
    name: "getIceServerConfig", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/v1/get-ice-server-config",
    validator: validate_GetIceServerConfig_21625771, base: "/",
    makeUrl: url_GetIceServerConfig_21625772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAlexaOfferToMaster_21626005 = ref object of OpenApiRestCall_21625426
proc url_SendAlexaOfferToMaster_21626007(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAlexaOfferToMaster_21626006(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This API allows you to connect WebRTC-enabled devices with Alexa display devices. When invoked, it sends the Alexa Session Description Protocol (SDP) offer to the master peer. The offer is delivered as soon as the master is connected to the specified signaling channel. This API returns the SDP answer from the connected master. If the master is not connected to the signaling channel, redelivery requests are made until the message expires.
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
  var valid_21626008 = header.getOrDefault("X-Amz-Date")
  valid_21626008 = validateParameter(valid_21626008, JString, required = false,
                                   default = nil)
  if valid_21626008 != nil:
    section.add "X-Amz-Date", valid_21626008
  var valid_21626009 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Security-Token", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Algorithm", valid_21626011
  var valid_21626012 = header.getOrDefault("X-Amz-Signature")
  valid_21626012 = validateParameter(valid_21626012, JString, required = false,
                                   default = nil)
  if valid_21626012 != nil:
    section.add "X-Amz-Signature", valid_21626012
  var valid_21626013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Credential")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Credential", valid_21626014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626016: Call_SendAlexaOfferToMaster_21626005;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This API allows you to connect WebRTC-enabled devices with Alexa display devices. When invoked, it sends the Alexa Session Description Protocol (SDP) offer to the master peer. The offer is delivered as soon as the master is connected to the specified signaling channel. This API returns the SDP answer from the connected master. If the master is not connected to the signaling channel, redelivery requests are made until the message expires.
  ## 
  let valid = call_21626016.validator(path, query, header, formData, body, _)
  let scheme = call_21626016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626016.makeUrl(scheme.get, call_21626016.host, call_21626016.base,
                               call_21626016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626016, uri, valid, _)

proc call*(call_21626017: Call_SendAlexaOfferToMaster_21626005; body: JsonNode): Recallable =
  ## sendAlexaOfferToMaster
  ## This API allows you to connect WebRTC-enabled devices with Alexa display devices. When invoked, it sends the Alexa Session Description Protocol (SDP) offer to the master peer. The offer is delivered as soon as the master is connected to the specified signaling channel. This API returns the SDP answer from the connected master. If the master is not connected to the signaling channel, redelivery requests are made until the message expires.
  ##   body: JObject (required)
  var body_21626018 = newJObject()
  if body != nil:
    body_21626018 = body
  result = call_21626017.call(nil, nil, nil, nil, body_21626018)

var sendAlexaOfferToMaster* = Call_SendAlexaOfferToMaster_21626005(
    name: "sendAlexaOfferToMaster", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/v1/send-alexa-offer-to-master",
    validator: validate_SendAlexaOfferToMaster_21626006, base: "/",
    makeUrl: url_SendAlexaOfferToMaster_21626007,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}