
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Video Streams Media
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
              path: JsonNode): string

  OpenApiRestCall_600413 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600413](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600413): Option[Scheme] {.used.} =
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
  awsServiceName = "kinesis-video-media"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetMedia_600755 = ref object of OpenApiRestCall_600413
proc url_GetMedia_600757(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMedia_600756(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Use this API to retrieve media content from a Kinesis video stream. In the request, you identify the stream name or stream Amazon Resource Name (ARN), and the starting chunk. Kinesis Video Streams then returns a stream of chunks in order by fragment number.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMedia</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>When you put media data (fragments) on a stream, Kinesis Video Streams stores each incoming fragment and related metadata in what is called a "chunk." For more information, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_dataplane_PutMedia.html">PutMedia</a>. The <code>GetMedia</code> API returns a stream of these chunks starting from the chunk that you specify in the request. </p> <p>The following limits apply when using the <code>GetMedia</code> API:</p> <ul> <li> <p>A client can call <code>GetMedia</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMedia</code> session. </p> </li> </ul> <note> <p>If an error is thrown after invoking a Kinesis Video Streams media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </note>
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
  var valid_600869 = header.getOrDefault("X-Amz-Date")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Date", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-Security-Token")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Security-Token", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Content-Sha256", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Algorithm")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Algorithm", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Signature")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Signature", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-SignedHeaders", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Credential")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Credential", valid_600875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600899: Call_GetMedia_600755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Use this API to retrieve media content from a Kinesis video stream. In the request, you identify the stream name or stream Amazon Resource Name (ARN), and the starting chunk. Kinesis Video Streams then returns a stream of chunks in order by fragment number.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMedia</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>When you put media data (fragments) on a stream, Kinesis Video Streams stores each incoming fragment and related metadata in what is called a "chunk." For more information, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_dataplane_PutMedia.html">PutMedia</a>. The <code>GetMedia</code> API returns a stream of these chunks starting from the chunk that you specify in the request. </p> <p>The following limits apply when using the <code>GetMedia</code> API:</p> <ul> <li> <p>A client can call <code>GetMedia</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMedia</code> session. </p> </li> </ul> <note> <p>If an error is thrown after invoking a Kinesis Video Streams media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </note>
  ## 
  let valid = call_600899.validator(path, query, header, formData, body)
  let scheme = call_600899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600899.url(scheme.get, call_600899.host, call_600899.base,
                         call_600899.route, valid.getOrDefault("path"))
  result = hook(call_600899, url, valid)

proc call*(call_600970: Call_GetMedia_600755; body: JsonNode): Recallable =
  ## getMedia
  ## <p> Use this API to retrieve media content from a Kinesis video stream. In the request, you identify the stream name or stream Amazon Resource Name (ARN), and the starting chunk. Kinesis Video Streams then returns a stream of chunks in order by fragment number.</p> <note> <p>You must first call the <code>GetDataEndpoint</code> API to get an endpoint. Then send the <code>GetMedia</code> requests to this endpoint using the <a href="https://docs.aws.amazon.com/cli/latest/reference/">--endpoint-url parameter</a>. </p> </note> <p>When you put media data (fragments) on a stream, Kinesis Video Streams stores each incoming fragment and related metadata in what is called a "chunk." For more information, see <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_dataplane_PutMedia.html">PutMedia</a>. The <code>GetMedia</code> API returns a stream of these chunks starting from the chunk that you specify in the request. </p> <p>The following limits apply when using the <code>GetMedia</code> API:</p> <ul> <li> <p>A client can call <code>GetMedia</code> up to five times per second per stream. </p> </li> <li> <p>Kinesis Video Streams sends media data at a rate of up to 25 megabytes per second (or 200 megabits per second) during a <code>GetMedia</code> session. </p> </li> </ul> <note> <p>If an error is thrown after invoking a Kinesis Video Streams media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: </p> <ul> <li> <p> <code>x-amz-ErrorType</code> HTTP header – contains a more specific error type in addition to what the HTTP status code provides. </p> </li> <li> <p> <code>x-amz-RequestId</code> HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id.</p> </li> </ul> <p>Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again.</p> <p>For more information, see the <b>Errors</b> section at the bottom of this topic, as well as <a href="https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html">Common Errors</a>. </p> </note>
  ##   body: JObject (required)
  var body_600971 = newJObject()
  if body != nil:
    body_600971 = body
  result = call_600970.call(nil, nil, nil, nil, body_600971)

var getMedia* = Call_GetMedia_600755(name: "getMedia", meth: HttpMethod.HttpPost,
                                  host: "kinesisvideo.amazonaws.com",
                                  route: "/getMedia",
                                  validator: validate_GetMedia_600756, base: "/",
                                  url: url_GetMedia_600757,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
