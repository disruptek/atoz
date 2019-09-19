
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetRawMessageContent_600755 = ref object of OpenApiRestCall_600413
proc url_GetRawMessageContent_600757(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "messageId" in path, "`messageId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/messages/"),
               (kind: VariableSegment, value: "messageId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRawMessageContent_600756(path: JsonNode; query: JsonNode;
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
  var valid_600883 = path.getOrDefault("messageId")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = nil)
  if valid_600883 != nil:
    section.add "messageId", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_GetRawMessageContent_600755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the raw content of an in-transit email message, in MIME format. 
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_GetRawMessageContent_600755; messageId: string): Recallable =
  ## getRawMessageContent
  ## Retrieves the raw content of an in-transit email message, in MIME format. 
  ##   messageId: string (required)
  ##            : The identifier of the email message to retrieve.
  var path_600985 = newJObject()
  add(path_600985, "messageId", newJString(messageId))
  result = call_600984.call(path_600985, nil, nil, nil, nil)

var getRawMessageContent* = Call_GetRawMessageContent_600755(
    name: "getRawMessageContent", meth: HttpMethod.HttpGet,
    host: "workmailmessageflow.amazonaws.com", route: "/messages/{messageId}",
    validator: validate_GetRawMessageContent_600756, base: "/",
    url: url_GetRawMessageContent_600757, schemes: {Scheme.Https, Scheme.Http})
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
