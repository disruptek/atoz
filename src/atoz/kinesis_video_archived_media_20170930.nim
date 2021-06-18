
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Video Streams Archived Media
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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "kinesisvideo.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kinesisvideo.ap-southeast-1.amazonaws.com", "us-west-2": "kinesisvideo.us-west-2.amazonaws.com", "eu-west-2": "kinesisvideo.eu-west-2.amazonaws.com", "ap-northeast-3": "kinesisvideo.ap-northeast-3.amazonaws.com", "eu-central-1": "kinesisvideo.eu-central-1.amazonaws.com", "us-east-2": "kinesisvideo.us-east-2.amazonaws.com", "us-east-1": "kinesisvideo.us-east-1.amazonaws.com", "cn-northwest-1": "kinesisvideo.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "kinesisvideo.ap-south-1.amazonaws.com", "eu-north-1": "kinesisvideo.eu-north-1.amazonaws.com", "ap-northeast-2": "kinesisvideo.ap-northeast-2.amazonaws.com", "us-west-1": "kinesisvideo.us-west-1.amazonaws.com", "us-gov-east-1": "kinesisvideo.us-gov-east-1.amazonaws.com", "eu-west-3": "kinesisvideo.eu-west-3.amazonaws.com", "cn-north-1": "kinesisvideo.cn-north-1.amazonaws.com.cn", "sa-east-1": "kinesisvideo.sa-east-1.amazonaws.com", "eu-west-1": "kinesisvideo.eu-west-1.amazonaws.com", "us-gov-west-1": "kinesisvideo.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kinesisvideo.ap-southeast-2.amazonaws.com", "ca-central-1": "kinesisvideo.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
  awsServiceName = "kinesis-video-archived-media"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetDASHStreamingSessionURL_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetDASHStreamingSessionURL_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDASHStreamingSessionURL_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves an MPEG Dynamic Adaptive Streaming over HTTP (DASH) URL for the stream. You can then open the URL in a media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through MPEG-DASH:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code> (for AAC) or A_MS/ACM (for G.711).</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see <a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>. For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>) or the <a href="http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html">MS Wave format</a>.</p> </li> </ul> <p>The following procedure shows how to use MPEG-DASH with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_DASH_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the MPEG-DASH URL using <code>GetDASHStreamingSessionURL</code>. Kinesis Video Streams creates an MPEG-DASH streaming session to be used for accessing content in a stream using the MPEG-DASH protocol. <code>GetDASHStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's MPEG-DASH <i>manifest</i> (the root resource needed for streaming with MPEG-DASH).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the manifest consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the MPEG-DASH manifest to a media player that supports the MPEG-DASH protocol. Kinesis Video Streams makes the initialization fragment and media fragments available through the manifest URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain encoded video frames or encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetDASHManifest:</b> Retrieves an MPEG DASH manifest, which contains the metadata for the media that you want to playback.</p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to MPEG-DASH sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active MPEG-DASH streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active MPEG-DASH sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other. </p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Security-Token", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Signature")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Signature", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Algorithm", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Date")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Date", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Credential")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Credential", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656378
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

proc call*(call_402656393: Call_GetDASHStreamingSessionURL_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves an MPEG Dynamic Adaptive Streaming over HTTP (DASH) URL for the stream. You can then open the URL in a media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through MPEG-DASH:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code> (for AAC) or A_MS/ACM (for G.711).</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see <a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>. For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>) or the <a href="http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html">MS Wave format</a>.</p> </li> </ul> <p>The following procedure shows how to use MPEG-DASH with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_DASH_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the MPEG-DASH URL using <code>GetDASHStreamingSessionURL</code>. Kinesis Video Streams creates an MPEG-DASH streaming session to be used for accessing content in a stream using the MPEG-DASH protocol. <code>GetDASHStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's MPEG-DASH <i>manifest</i> (the root resource needed for streaming with MPEG-DASH).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the manifest consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the MPEG-DASH manifest to a media player that supports the MPEG-DASH protocol. Kinesis Video Streams makes the initialization fragment and media fragments available through the manifest URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain encoded video frames or encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetDASHManifest:</b> Retrieves an MPEG DASH manifest, which contains the metadata for the media that you want to playback.</p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to MPEG-DASH sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active MPEG-DASH streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active MPEG-DASH sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other. </p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                                                                         ## 
  let valid = call_402656393.validator(path, query, header, formData, body, _)
  let scheme = call_402656393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656393.makeUrl(scheme.get, call_402656393.host, call_402656393.base,
                                   call_402656393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656393, uri, valid, _)

proc call*(call_402656442: Call_GetDASHStreamingSessionURL_402656288;
           body: JsonNode): Recallable =
  ## getDASHStreamingSessionURL
  ## <p>Retrieves an MPEG Dynamic Adaptive Streaming over HTTP (DASH) URL for the stream. You can then open the URL in a media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through MPEG-DASH:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code> (for AAC) or A_MS/ACM (for G.711).</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see <a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>. For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>) or the <a href="http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html">MS Wave format</a>.</p> </li> </ul> <p>The following procedure shows how to use MPEG-DASH with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_DASH_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the MPEG-DASH URL using <code>GetDASHStreamingSessionURL</code>. Kinesis Video Streams creates an MPEG-DASH streaming session to be used for accessing content in a stream using the MPEG-DASH protocol. <code>GetDASHStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's MPEG-DASH <i>manifest</i> (the root resource needed for streaming with MPEG-DASH).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the manifest consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the MPEG-DASH manifest to a media player that supports the MPEG-DASH protocol. Kinesis Video Streams makes the initialization fragment and media fragments available through the manifest URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain encoded video frames or encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetDASHManifest:</b> Retrieves an MPEG DASH manifest, which contains the metadata for the media that you want to playback.</p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to MPEG-DASH sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active MPEG-DASH streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active MPEG-DASH sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other. </p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656443 = newJObject()
  if body != nil:
    body_402656443 = body
  result = call_402656442.call(nil, nil, nil, nil, body_402656443)

var getDASHStreamingSessionURL* = Call_GetDASHStreamingSessionURL_402656288(
    name: "getDASHStreamingSessionURL", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/getDASHStreamingSessionURL",
    validator: validate_GetDASHStreamingSessionURL_402656289, base: "/",
    makeUrl: url_GetDASHStreamingSessionURL_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHLSStreamingSessionURL_402656470 = ref object of OpenApiRestCall_402656038
proc url_GetHLSStreamingSessionURL_402656472(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetHLSStreamingSessionURL_402656471(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves an HTTP Live Streaming (HLS) URL for the stream. You can then open the URL in a browser or media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through HLS:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or <code>V_MPEG/ISO/HEVC</code> (for h.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code>.</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format or HEVC for H.265 format (<a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>). For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>).</p> </li> </ul> <p>Kinesis Video Streams HLS sessions contain fragments in the fragmented MPEG-4 form (also called fMP4 or CMAF) or the MPEG-2 form (also called TS chunks, which the HLS specification also supports). For more information about HLS fragment types, see the <a href="https://tools.ietf.org/html/draft-pantos-http-live-streaming-23">HLS specification</a>.</p> <p>The following procedure shows how to use HLS with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_HLS_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the HLS URL using <code>GetHLSStreamingSessionURL</code>. Kinesis Video Streams creates an HLS streaming session to be used for accessing content in a stream using the HLS protocol. <code>GetHLSStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's HLS <i>master playlist</i> (the root resource needed for streaming with HLS).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the playlist consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the HLS master playlist to a media player that supports the HLS protocol. Kinesis Video Streams makes the HLS media playlist, initialization fragment, and media fragments available through the master playlist URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain H.264-encoded video frames or AAC-encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetHLSMasterPlaylist:</b> Retrieves an HLS master playlist, which contains a URL for the <code>GetHLSMediaPlaylist</code> action for each track, and additional metadata for the media player, including estimated bitrate and resolution.</p> </li> <li> <p> <b>GetHLSMediaPlaylist:</b> Retrieves an HLS media playlist, which contains a URL to access the MP4 initialization fragment with the <code>GetMP4InitFragment</code> action, and URLs to access the MP4 media fragments with the <code>GetMP4MediaFragment</code> actions. The HLS media playlist also contains metadata about the stream that the player needs to play it, such as whether the <code>PlaybackMode</code> is <code>LIVE</code> or <code>ON_DEMAND</code>. The HLS media playlist is typically static for sessions with a <code>PlaybackType</code> of <code>ON_DEMAND</code>. The HLS media playlist is continually updated with new fragments for sessions with a <code>PlaybackType</code> of <code>LIVE</code>. There is a distinct HLS media playlist for the video track and the audio track (if applicable) that contains MP4 media URLs for the specific track. </p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> <li> <p> <b>GetTSFragment:</b> Retrieves MPEG TS fragments containing both initialization and media data for all tracks in the stream.</p> <note> <p>If the <code>ContainerFormat</code> is <code>MPEG_TS</code>, this API is used instead of <code>GetMP4InitFragment</code> and <code>GetMP4MediaFragment</code> to retrieve stream media.</p> </note> <p>Data retrieved with this action is billable. For more information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Kinesis Video Streams pricing</a>.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to HLS sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active HLS streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active HLS sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other.</p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656473 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656473 = validateParameter(valid_402656473, JString,
                                      required = false, default = nil)
  if valid_402656473 != nil:
    section.add "X-Amz-Security-Token", valid_402656473
  var valid_402656474 = header.getOrDefault("X-Amz-Signature")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-Signature", valid_402656474
  var valid_402656475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656475
  var valid_402656476 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Algorithm", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Date")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Date", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Credential")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Credential", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656479
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

proc call*(call_402656481: Call_GetHLSStreamingSessionURL_402656470;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves an HTTP Live Streaming (HLS) URL for the stream. You can then open the URL in a browser or media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through HLS:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or <code>V_MPEG/ISO/HEVC</code> (for h.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code>.</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format or HEVC for H.265 format (<a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>). For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>).</p> </li> </ul> <p>Kinesis Video Streams HLS sessions contain fragments in the fragmented MPEG-4 form (also called fMP4 or CMAF) or the MPEG-2 form (also called TS chunks, which the HLS specification also supports). For more information about HLS fragment types, see the <a href="https://tools.ietf.org/html/draft-pantos-http-live-streaming-23">HLS specification</a>.</p> <p>The following procedure shows how to use HLS with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_HLS_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the HLS URL using <code>GetHLSStreamingSessionURL</code>. Kinesis Video Streams creates an HLS streaming session to be used for accessing content in a stream using the HLS protocol. <code>GetHLSStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's HLS <i>master playlist</i> (the root resource needed for streaming with HLS).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the playlist consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the HLS master playlist to a media player that supports the HLS protocol. Kinesis Video Streams makes the HLS media playlist, initialization fragment, and media fragments available through the master playlist URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain H.264-encoded video frames or AAC-encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetHLSMasterPlaylist:</b> Retrieves an HLS master playlist, which contains a URL for the <code>GetHLSMediaPlaylist</code> action for each track, and additional metadata for the media player, including estimated bitrate and resolution.</p> </li> <li> <p> <b>GetHLSMediaPlaylist:</b> Retrieves an HLS media playlist, which contains a URL to access the MP4 initialization fragment with the <code>GetMP4InitFragment</code> action, and URLs to access the MP4 media fragments with the <code>GetMP4MediaFragment</code> actions. The HLS media playlist also contains metadata about the stream that the player needs to play it, such as whether the <code>PlaybackMode</code> is <code>LIVE</code> or <code>ON_DEMAND</code>. The HLS media playlist is typically static for sessions with a <code>PlaybackType</code> of <code>ON_DEMAND</code>. The HLS media playlist is continually updated with new fragments for sessions with a <code>PlaybackType</code> of <code>LIVE</code>. There is a distinct HLS media playlist for the video track and the audio track (if applicable) that contains MP4 media URLs for the specific track. </p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> <li> <p> <b>GetTSFragment:</b> Retrieves MPEG TS fragments containing both initialization and media data for all tracks in the stream.</p> <note> <p>If the <code>ContainerFormat</code> is <code>MPEG_TS</code>, this API is used instead of <code>GetMP4InitFragment</code> and <code>GetMP4MediaFragment</code> to retrieve stream media.</p> </note> <p>Data retrieved with this action is billable. For more information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Kinesis Video Streams pricing</a>.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to HLS sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active HLS streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active HLS sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other.</p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                                                                         ## 
  let valid = call_402656481.validator(path, query, header, formData, body, _)
  let scheme = call_402656481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656481.makeUrl(scheme.get, call_402656481.host, call_402656481.base,
                                   call_402656481.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656481, uri, valid, _)

proc call*(call_402656482: Call_GetHLSStreamingSessionURL_402656470;
           body: JsonNode): Recallable =
  ## getHLSStreamingSessionURL
  ## <p>Retrieves an HTTP Live Streaming (HLS) URL for the stream. You can then open the URL in a browser or media player to view the stream contents.</p> <p>Both the <code>StreamName</code> and the <code>StreamARN</code> parameters are optional, but you must specify either the <code>StreamName</code> or the <code>StreamARN</code> when invoking this API operation.</p> <p>An Amazon Kinesis video stream has the following requirements for providing data through HLS:</p> <ul> <li> <p>The media must contain h.264 or h.265 encoded video and, optionally, AAC encoded audio. Specifically, the codec ID of track 1 should be <code>V_MPEG/ISO/AVC</code> (for h.264) or <code>V_MPEG/ISO/HEVC</code> (for h.265). Optionally, the codec ID of track 2 should be <code>A_AAC</code>.</p> </li> <li> <p>Data retention must be greater than 0.</p> </li> <li> <p>The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format or HEVC for H.265 format (<a href="https://www.iso.org/standard/55980.html">MPEG-4 specification ISO/IEC 14496-15</a>). For information about adapting stream data to a given format, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html">NAL Adaptation Flags</a>.</p> </li> <li> <p>The audio track (if present) of each fragment must contain codec private data in the AAC format (<a href="https://www.iso.org/standard/43345.html">AAC specification ISO/IEC 13818-7</a>).</p> </li> </ul> <p>Kinesis Video Streams HLS sessions contain fragments in the fragmented MPEG-4 form (also called fMP4 or CMAF) or the MPEG-2 form (also called TS chunks, which the HLS specification also supports). For more information about HLS fragment types, see the <a href="https://tools.ietf.org/html/draft-pantos-http-live-streaming-23">HLS specification</a>.</p> <p>The following procedure shows how to use HLS with Kinesis Video Streams:</p> <ol> <li> <p>Get an endpoint using <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html">GetDataEndpoint</a>, specifying <code>GET_HLS_STREAMING_SESSION_URL</code> for the <code>APIName</code> parameter.</p> </li> <li> <p>Retrieve the HLS URL using <code>GetHLSStreamingSessionURL</code>. Kinesis Video Streams creates an HLS streaming session to be used for accessing content in a stream using the HLS protocol. <code>GetHLSStreamingSessionURL</code> returns an authenticated URL (that includes an encrypted session token) for the session's HLS <i>master playlist</i> (the root resource needed for streaming with HLS).</p> <note> <p>Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials.</p> </note> <p>The media that is made available through the playlist consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available.</p> </li> <li> <p>Provide the URL (containing the encrypted session token) for the HLS master playlist to a media player that supports the HLS protocol. Kinesis Video Streams makes the HLS media playlist, initialization fragment, and media fragments available through the master playlist URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain H.264-encoded video frames or AAC-encoded audio samples.</p> </li> <li> <p>The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions:</p> <ul> <li> <p> <b>GetHLSMasterPlaylist:</b> Retrieves an HLS master playlist, which contains a URL for the <code>GetHLSMediaPlaylist</code> action for each track, and additional metadata for the media player, including estimated bitrate and resolution.</p> </li> <li> <p> <b>GetHLSMediaPlaylist:</b> Retrieves an HLS media playlist, which contains a URL to access the MP4 initialization fragment with the <code>GetMP4InitFragment</code> action, and URLs to access the MP4 media fragments with the <code>GetMP4MediaFragment</code> actions. The HLS media playlist also contains metadata about the stream that the player needs to play it, such as whether the <code>PlaybackMode</code> is <code>LIVE</code> or <code>ON_DEMAND</code>. The HLS media playlist is typically static for sessions with a <code>PlaybackType</code> of <code>ON_DEMAND</code>. The HLS media playlist is continually updated with new fragments for sessions with a <code>PlaybackType</code> of <code>LIVE</code>. There is a distinct HLS media playlist for the video track and the audio track (if applicable) that contains MP4 media URLs for the specific track. </p> </li> <li> <p> <b>GetMP4InitFragment:</b> Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "<code>fytp</code>" and "<code>moov</code>" MP4 atoms, and the child atoms that are needed to initialize the media player decoder.</p> <p>The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames.</p> </li> <li> <p> <b>GetMP4MediaFragment:</b> Retrieves MP4 media fragments. These fragments contain the "<code>moof</code>" and "<code>mdat</code>" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. </p> <note> <p>After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video.</p> </note> <p>Data retrieved with this action is billable. See <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Pricing</a> for details.</p> </li> <li> <p> <b>GetTSFragment:</b> Retrieves MPEG TS fragments containing both initialization and media data for all tracks in the stream.</p> <note> <p>If the <code>ContainerFormat</code> is <code>MPEG_TS</code>, this API is used instead of <code>GetMP4InitFragment</code> and <code>GetMP4MediaFragment</code> to retrieve stream media.</p> </note> <p>Data retrieved with this action is billable. For more information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Kinesis Video Streams pricing</a>.</p> </li> </ul> </li> </ol> <note> <p>The following restrictions apply to HLS sessions:</p> <ul> <li> <p>A streaming session URL should not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html">Kinesis Video Streams Limits</a>.</p> </li> <li> <p>A Kinesis video stream can have a maximum of ten active HLS streaming sessions. If a new session is created when the maximum number of sessions is already active, the oldest (earliest created) session is closed. The number of active <code>GetMedia</code> connections on a Kinesis video stream does not count against this limit, and the number of active HLS sessions does not count against the active <code>GetMedia</code> connection limit.</p> <note> <p>The maximum limits for active HLS and MPEG-DASH streaming sessions are independent of each other.</p> </note> </li> </ul> </note> <p>You can monitor the amount of data that the media player consumes by monitoring the <code>GetMP4MediaFragment.OutgoingBytes</code> Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see <a href="http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html">Monitoring Kinesis Video Streams</a>. For pricing information, see <a href="https://aws.amazon.com/kinesis/video-streams/pricing/">Amazon Kinesis Video Streams Pricing</a> and <a href="https://aws.amazon.com/pricing/">AWS Pricing</a>. Charges for both HLS sessions and outgoing AWS data apply.</p> <p>For more information about HLS, see <a href="https://developer.apple.com/streaming/">HTTP Live Streaming</a> on the <a href="https://developer.apple.com">Apple Developer site</a>.</p> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656483 = newJObject()
  if body != nil:
    body_402656483 = body
  result = call_402656482.call(nil, nil, nil, nil, body_402656483)

var getHLSStreamingSessionURL* = Call_GetHLSStreamingSessionURL_402656470(
    name: "getHLSStreamingSessionURL", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/getHLSStreamingSessionURL",
    validator: validate_GetHLSStreamingSessionURL_402656471, base: "/",
    makeUrl: url_GetHLSStreamingSessionURL_402656472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMediaForFragmentList_402656484 = ref object of OpenApiRestCall_402656038
proc url_GetMediaForFragmentList_402656486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMediaForFragmentList_402656485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets media for a list of fragments (specified by fragment number) from the archived data in an Amazon Kinesis video stream.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMediaForFragmentList</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>The following limits apply when using the <code>GetMediaForFragmentList</code> API:</p> <ul> <li> <p>A client can call <code>GetMediaForFragmentList</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMediaForFragmentList</code> session. </p> </li> </ul> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_GetMediaForFragmentList_402656484;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets media for a list of fragments (specified by fragment number) from the archived data in an Amazon Kinesis video stream.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMediaForFragmentList</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>The following limits apply when using the <code>GetMediaForFragmentList</code> API:</p> <ul> <li> <p>A client can call <code>GetMediaForFragmentList</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMediaForFragmentList</code> session. </p> </li> </ul> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_GetMediaForFragmentList_402656484;
           body: JsonNode): Recallable =
  ## getMediaForFragmentList
  ## <p>Gets media for a list of fragments (specified by fragment number) from the archived data in an Amazon Kinesis video stream.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMediaForFragmentList</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>The following limits apply when using the <code>GetMediaForFragmentList</code> API:</p> <ul> <li> <p>A client can call <code>GetMediaForFragmentList</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMediaForFragmentList</code> session. </p> </li> </ul> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var getMediaForFragmentList* = Call_GetMediaForFragmentList_402656484(
    name: "getMediaForFragmentList", meth: HttpMethod.HttpPost,
    host: "kinesisvideo.amazonaws.com", route: "/getMediaForFragmentList",
    validator: validate_GetMediaForFragmentList_402656485, base: "/",
    makeUrl: url_GetMediaForFragmentList_402656486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFragments_402656498 = ref object of OpenApiRestCall_402656038
proc url_ListFragments_402656500(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFragments_402656499(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of <a>Fragment</a> objects from the specified stream and timestamp range within the archived data.</p> <p>Listing fragments is eventually consistent. This means that even if the producer receives an acknowledgment that a fragment is persisted, the result might not be returned immediately from a request to <code>ListFragments</code>. However, results are typically available in less than one second.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>ListFragments</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
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
  var valid_402656501 = query.getOrDefault("MaxResults")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "MaxResults", valid_402656501
  var valid_402656502 = query.getOrDefault("NextToken")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "NextToken", valid_402656502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656503 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Security-Token", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Signature")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Signature", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Algorithm", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Date")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Date", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Credential")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Credential", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656509
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

proc call*(call_402656511: Call_ListFragments_402656498; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of <a>Fragment</a> objects from the specified stream and timestamp range within the archived data.</p> <p>Listing fragments is eventually consistent. This means that even if the producer receives an acknowledgment that a fragment is persisted, the result might not be returned immediately from a request to <code>ListFragments</code>. However, results are typically available in less than one second.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>ListFragments</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
                                                                                         ## 
  let valid = call_402656511.validator(path, query, header, formData, body, _)
  let scheme = call_402656511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656511.makeUrl(scheme.get, call_402656511.host, call_402656511.base,
                                   call_402656511.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656511, uri, valid, _)

proc call*(call_402656512: Call_ListFragments_402656498; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFragments
  ## <p>Returns a list of <a>Fragment</a> objects from the specified stream and timestamp range within the archived data.</p> <p>Listing fragments is eventually consistent. This means that even if the producer receives an acknowledgment that a fragment is persisted, the result might not be returned immediately from a request to <code>ListFragments</code>. However, results are typically available in less than one second.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>ListFragments</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <important> <p>If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## token
  var query_402656513 = newJObject()
  var body_402656514 = newJObject()
  add(query_402656513, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656514 = body
  add(query_402656513, "NextToken", newJString(NextToken))
  result = call_402656512.call(nil, query_402656513, nil, nil, body_402656514)

var listFragments* = Call_ListFragments_402656498(name: "listFragments",
    meth: HttpMethod.HttpPost, host: "kinesisvideo.amazonaws.com",
    route: "/listFragments", validator: validate_ListFragments_402656499,
    base: "/", makeUrl: url_ListFragments_402656500,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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