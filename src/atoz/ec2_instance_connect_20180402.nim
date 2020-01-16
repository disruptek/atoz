
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS EC2 Instance Connect
## version: 2018-04-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS EC2 Connect Service is a service that enables system administrators to publish temporary SSH keys to their EC2 instances in order to establish connections to their instances without leaving a permanent authentication option.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ec2-instance-connect/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ec2-instance-connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ec2-instance-connect.ap-southeast-1.amazonaws.com", "us-west-2": "ec2-instance-connect.us-west-2.amazonaws.com", "eu-west-2": "ec2-instance-connect.eu-west-2.amazonaws.com", "ap-northeast-3": "ec2-instance-connect.ap-northeast-3.amazonaws.com", "eu-central-1": "ec2-instance-connect.eu-central-1.amazonaws.com", "us-east-2": "ec2-instance-connect.us-east-2.amazonaws.com", "us-east-1": "ec2-instance-connect.us-east-1.amazonaws.com", "cn-northwest-1": "ec2-instance-connect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "ec2-instance-connect.ap-south-1.amazonaws.com", "eu-north-1": "ec2-instance-connect.eu-north-1.amazonaws.com", "ap-northeast-2": "ec2-instance-connect.ap-northeast-2.amazonaws.com", "us-west-1": "ec2-instance-connect.us-west-1.amazonaws.com", "us-gov-east-1": "ec2-instance-connect.us-gov-east-1.amazonaws.com", "eu-west-3": "ec2-instance-connect.eu-west-3.amazonaws.com", "cn-north-1": "ec2-instance-connect.cn-north-1.amazonaws.com.cn", "sa-east-1": "ec2-instance-connect.sa-east-1.amazonaws.com", "eu-west-1": "ec2-instance-connect.eu-west-1.amazonaws.com", "us-gov-west-1": "ec2-instance-connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ec2-instance-connect.ap-southeast-2.amazonaws.com", "ca-central-1": "ec2-instance-connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ec2-instance-connect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ec2-instance-connect.ap-southeast-1.amazonaws.com",
      "us-west-2": "ec2-instance-connect.us-west-2.amazonaws.com",
      "eu-west-2": "ec2-instance-connect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ec2-instance-connect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ec2-instance-connect.eu-central-1.amazonaws.com",
      "us-east-2": "ec2-instance-connect.us-east-2.amazonaws.com",
      "us-east-1": "ec2-instance-connect.us-east-1.amazonaws.com",
      "cn-northwest-1": "ec2-instance-connect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ec2-instance-connect.ap-south-1.amazonaws.com",
      "eu-north-1": "ec2-instance-connect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ec2-instance-connect.ap-northeast-2.amazonaws.com",
      "us-west-1": "ec2-instance-connect.us-west-1.amazonaws.com",
      "us-gov-east-1": "ec2-instance-connect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ec2-instance-connect.eu-west-3.amazonaws.com",
      "cn-north-1": "ec2-instance-connect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ec2-instance-connect.sa-east-1.amazonaws.com",
      "eu-west-1": "ec2-instance-connect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ec2-instance-connect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ec2-instance-connect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ec2-instance-connect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ec2-instance-connect"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_SendSSHPublicKey_605918 = ref object of OpenApiRestCall_605580
proc url_SendSSHPublicKey_605920(protocol: Scheme; host: string; base: string;
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

proc validate_SendSSHPublicKey_605919(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Pushes an SSH public key to a particular OS user on a given EC2 instance for 60 seconds.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606045 = header.getOrDefault("X-Amz-Target")
  valid_606045 = validateParameter(valid_606045, JString, required = true, default = newJString(
      "AWSEC2InstanceConnectService.SendSSHPublicKey"))
  if valid_606045 != nil:
    section.add "X-Amz-Target", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Signature")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Signature", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Content-Sha256", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Date")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Date", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Credential")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Credential", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Security-Token")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Security-Token", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Algorithm")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Algorithm", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-SignedHeaders", valid_606052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_SendSSHPublicKey_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Pushes an SSH public key to a particular OS user on a given EC2 instance for 60 seconds.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_SendSSHPublicKey_605918; body: JsonNode): Recallable =
  ## sendSSHPublicKey
  ## Pushes an SSH public key to a particular OS user on a given EC2 instance for 60 seconds.
  ##   body: JObject (required)
  var body_606148 = newJObject()
  if body != nil:
    body_606148 = body
  result = call_606147.call(nil, nil, nil, nil, body_606148)

var sendSSHPublicKey* = Call_SendSSHPublicKey_605918(name: "sendSSHPublicKey",
    meth: HttpMethod.HttpPost, host: "ec2-instance-connect.amazonaws.com",
    route: "/#X-Amz-Target=AWSEC2InstanceConnectService.SendSSHPublicKey",
    validator: validate_SendSSHPublicKey_605919, base: "/",
    url: url_SendSSHPublicKey_605920, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
