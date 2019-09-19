
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QLDB Session
## version: 2019-07-11
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The transactional data APIs for Amazon QLDB
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/qldb/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "session.qldb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "session.qldb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "session.qldb.us-west-2.amazonaws.com",
                           "eu-west-2": "session.qldb.eu-west-2.amazonaws.com", "ap-northeast-3": "session.qldb.ap-northeast-3.amazonaws.com", "eu-central-1": "session.qldb.eu-central-1.amazonaws.com",
                           "us-east-2": "session.qldb.us-east-2.amazonaws.com",
                           "us-east-1": "session.qldb.us-east-1.amazonaws.com", "cn-northwest-1": "session.qldb.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "session.qldb.ap-south-1.amazonaws.com", "eu-north-1": "session.qldb.eu-north-1.amazonaws.com", "ap-northeast-2": "session.qldb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "session.qldb.us-west-1.amazonaws.com", "us-gov-east-1": "session.qldb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "session.qldb.eu-west-3.amazonaws.com", "cn-north-1": "session.qldb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "session.qldb.sa-east-1.amazonaws.com",
                           "eu-west-1": "session.qldb.eu-west-1.amazonaws.com", "us-gov-west-1": "session.qldb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "session.qldb.ap-southeast-2.amazonaws.com", "ca-central-1": "session.qldb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "session.qldb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "session.qldb.ap-southeast-1.amazonaws.com",
      "us-west-2": "session.qldb.us-west-2.amazonaws.com",
      "eu-west-2": "session.qldb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "session.qldb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "session.qldb.eu-central-1.amazonaws.com",
      "us-east-2": "session.qldb.us-east-2.amazonaws.com",
      "us-east-1": "session.qldb.us-east-1.amazonaws.com",
      "cn-northwest-1": "session.qldb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "session.qldb.ap-south-1.amazonaws.com",
      "eu-north-1": "session.qldb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "session.qldb.ap-northeast-2.amazonaws.com",
      "us-west-1": "session.qldb.us-west-1.amazonaws.com",
      "us-gov-east-1": "session.qldb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "session.qldb.eu-west-3.amazonaws.com",
      "cn-north-1": "session.qldb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "session.qldb.sa-east-1.amazonaws.com",
      "eu-west-1": "session.qldb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "session.qldb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "session.qldb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "session.qldb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "qldb-session"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_SendCommand_600755 = ref object of OpenApiRestCall_600413
proc url_SendCommand_600757(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendCommand_600756(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends a command to an Amazon QLDB ledger.
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
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600884 = header.getOrDefault("X-Amz-Target")
  valid_600884 = validateParameter(valid_600884, JString, required = true, default = newJString(
      "QLDBSession.SendCommand"))
  if valid_600884 != nil:
    section.add "X-Amz-Target", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Content-Sha256", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Algorithm")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Algorithm", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Signature")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Signature", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-SignedHeaders", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Credential")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Credential", valid_600889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_SendCommand_600755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a command to an Amazon QLDB ledger.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_SendCommand_600755; body: JsonNode): Recallable =
  ## sendCommand
  ## Sends a command to an Amazon QLDB ledger.
  ##   body: JObject (required)
  var body_600985 = newJObject()
  if body != nil:
    body_600985 = body
  result = call_600984.call(nil, nil, nil, nil, body_600985)

var sendCommand* = Call_SendCommand_600755(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "session.qldb.amazonaws.com", route: "/#X-Amz-Target=QLDBSession.SendCommand",
                                        validator: validate_SendCommand_600756,
                                        base: "/", url: url_SendCommand_600757,
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
