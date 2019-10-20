
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon WorkMail Message Flow
## version: 2019-05-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The WorkMail Message Flow API provides access to email messages as they are being sent and received by a WorkMail organization.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/workmailmessageflow/
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

  OpenApiRestCall_592355 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592355](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592355): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "workmailmessageflow.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workmailmessageflow.ap-southeast-1.amazonaws.com", "us-west-2": "workmailmessageflow.us-west-2.amazonaws.com", "eu-west-2": "workmailmessageflow.eu-west-2.amazonaws.com", "ap-northeast-3": "workmailmessageflow.ap-northeast-3.amazonaws.com", "eu-central-1": "workmailmessageflow.eu-central-1.amazonaws.com", "us-east-2": "workmailmessageflow.us-east-2.amazonaws.com", "us-east-1": "workmailmessageflow.us-east-1.amazonaws.com", "cn-northwest-1": "workmailmessageflow.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "workmailmessageflow.ap-south-1.amazonaws.com", "eu-north-1": "workmailmessageflow.eu-north-1.amazonaws.com", "ap-northeast-2": "workmailmessageflow.ap-northeast-2.amazonaws.com", "us-west-1": "workmailmessageflow.us-west-1.amazonaws.com", "us-gov-east-1": "workmailmessageflow.us-gov-east-1.amazonaws.com", "eu-west-3": "workmailmessageflow.eu-west-3.amazonaws.com", "cn-north-1": "workmailmessageflow.cn-north-1.amazonaws.com.cn", "sa-east-1": "workmailmessageflow.sa-east-1.amazonaws.com", "eu-west-1": "workmailmessageflow.eu-west-1.amazonaws.com", "us-gov-west-1": "workmailmessageflow.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workmailmessageflow.ap-southeast-2.amazonaws.com", "ca-central-1": "workmailmessageflow.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "workmailmessageflow.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "workmailmessageflow.ap-southeast-1.amazonaws.com",
      "us-west-2": "workmailmessageflow.us-west-2.amazonaws.com",
      "eu-west-2": "workmailmessageflow.eu-west-2.amazonaws.com",
      "ap-northeast-3": "workmailmessageflow.ap-northeast-3.amazonaws.com",
      "eu-central-1": "workmailmessageflow.eu-central-1.amazonaws.com",
      "us-east-2": "workmailmessageflow.us-east-2.amazonaws.com",
      "us-east-1": "workmailmessageflow.us-east-1.amazonaws.com",
      "cn-northwest-1": "workmailmessageflow.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "workmailmessageflow.ap-south-1.amazonaws.com",
      "eu-north-1": "workmailmessageflow.eu-north-1.amazonaws.com",
      "ap-northeast-2": "workmailmessageflow.ap-northeast-2.amazonaws.com",
      "us-west-1": "workmailmessageflow.us-west-1.amazonaws.com",
      "us-gov-east-1": "workmailmessageflow.us-gov-east-1.amazonaws.com",
      "eu-west-3": "workmailmessageflow.eu-west-3.amazonaws.com",
      "cn-north-1": "workmailmessageflow.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "workmailmessageflow.sa-east-1.amazonaws.com",
      "eu-west-1": "workmailmessageflow.eu-west-1.amazonaws.com",
      "us-gov-west-1": "workmailmessageflow.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "workmailmessageflow.ap-southeast-2.amazonaws.com",
      "ca-central-1": "workmailmessageflow.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "workmailmessageflow"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetRawMessageContent_592694 = ref object of OpenApiRestCall_592355
proc url_GetRawMessageContent_592696(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "messageId" in path, "`messageId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/messages/"),
               (kind: VariableSegment, value: "messageId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRawMessageContent_592695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the raw content of an in-transit email message, in MIME format. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   messageId: JString (required)
  ##            : The identifier of the email message to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `messageId` field"
  var valid_592822 = path.getOrDefault("messageId")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "messageId", valid_592822
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
  var valid_592823 = header.getOrDefault("X-Amz-Signature")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Signature", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Content-Sha256", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Date")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Date", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Credential")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Credential", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Security-Token")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Security-Token", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-Algorithm")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-Algorithm", valid_592828
  var valid_592829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592829 = validateParameter(valid_592829, JString, required = false,
                                 default = nil)
  if valid_592829 != nil:
    section.add "X-Amz-SignedHeaders", valid_592829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592852: Call_GetRawMessageContent_592694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the raw content of an in-transit email message, in MIME format. 
  ## 
  let valid = call_592852.validator(path, query, header, formData, body)
  let scheme = call_592852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592852.url(scheme.get, call_592852.host, call_592852.base,
                         call_592852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592852, url, valid)

proc call*(call_592923: Call_GetRawMessageContent_592694; messageId: string): Recallable =
  ## getRawMessageContent
  ## Retrieves the raw content of an in-transit email message, in MIME format. 
  ##   messageId: string (required)
  ##            : The identifier of the email message to retrieve.
  var path_592924 = newJObject()
  add(path_592924, "messageId", newJString(messageId))
  result = call_592923.call(path_592924, nil, nil, nil, nil)

var getRawMessageContent* = Call_GetRawMessageContent_592694(
    name: "getRawMessageContent", meth: HttpMethod.HttpGet,
    host: "workmailmessageflow.amazonaws.com", route: "/messages/{messageId}",
    validator: validate_GetRawMessageContent_592695, base: "/",
    url: url_GetRawMessageContent_592696, schemes: {Scheme.Https, Scheme.Http})
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
