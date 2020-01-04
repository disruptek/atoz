
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Mobile Analytics
## version: 2014-06-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Mobile Analytics is a service for collecting, visualizing, and understanding app usage data at scale.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mobileanalytics/
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mobileanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mobileanalytics.ap-southeast-1.amazonaws.com", "us-west-2": "mobileanalytics.us-west-2.amazonaws.com", "eu-west-2": "mobileanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "mobileanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "mobileanalytics.eu-central-1.amazonaws.com", "us-east-2": "mobileanalytics.us-east-2.amazonaws.com", "us-east-1": "mobileanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "mobileanalytics.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mobileanalytics.ap-south-1.amazonaws.com", "eu-north-1": "mobileanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "mobileanalytics.ap-northeast-2.amazonaws.com", "us-west-1": "mobileanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "mobileanalytics.us-gov-east-1.amazonaws.com", "eu-west-3": "mobileanalytics.eu-west-3.amazonaws.com", "cn-north-1": "mobileanalytics.cn-north-1.amazonaws.com.cn", "sa-east-1": "mobileanalytics.sa-east-1.amazonaws.com", "eu-west-1": "mobileanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "mobileanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mobileanalytics.ap-southeast-2.amazonaws.com", "ca-central-1": "mobileanalytics.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mobileanalytics.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mobileanalytics.ap-southeast-1.amazonaws.com",
      "us-west-2": "mobileanalytics.us-west-2.amazonaws.com",
      "eu-west-2": "mobileanalytics.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mobileanalytics.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mobileanalytics.eu-central-1.amazonaws.com",
      "us-east-2": "mobileanalytics.us-east-2.amazonaws.com",
      "us-east-1": "mobileanalytics.us-east-1.amazonaws.com",
      "cn-northwest-1": "mobileanalytics.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mobileanalytics.ap-south-1.amazonaws.com",
      "eu-north-1": "mobileanalytics.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mobileanalytics.ap-northeast-2.amazonaws.com",
      "us-west-1": "mobileanalytics.us-west-1.amazonaws.com",
      "us-gov-east-1": "mobileanalytics.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mobileanalytics.eu-west-3.amazonaws.com",
      "cn-north-1": "mobileanalytics.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mobileanalytics.sa-east-1.amazonaws.com",
      "eu-west-1": "mobileanalytics.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mobileanalytics.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mobileanalytics.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mobileanalytics.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mobileanalytics"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutEvents_601718 = ref object of OpenApiRestCall_601380
proc url_PutEvents_601720(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_601719(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## The PutEvents operation records one or more events. You can have up to 1,500 unique custom events per app, any combination of up to 40 attributes and metrics per custom event, and any number of attribute or metric values.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-Client-Context: JString (required)
  ##                       : The client context including the client ID, app title, app version and package name.
  ##   X-Amz-Signature: JString
  ##   x-amz-Client-Context-Encoding: JString
  ##                                : The encoding used for the client context.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil, "header argument is necessary due to required `x-amz-Client-Context` field"
  var valid_601832 = header.getOrDefault("x-amz-Client-Context")
  valid_601832 = validateParameter(valid_601832, JString, required = true,
                                 default = nil)
  if valid_601832 != nil:
    section.add "x-amz-Client-Context", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Signature")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Signature", valid_601833
  var valid_601834 = header.getOrDefault("x-amz-Client-Context-Encoding")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "x-amz-Client-Context-Encoding", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Content-Sha256", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Date")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Date", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Credential")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Credential", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Security-Token")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Security-Token", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Algorithm")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Algorithm", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-SignedHeaders", valid_601840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601864: Call_PutEvents_601718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The PutEvents operation records one or more events. You can have up to 1,500 unique custom events per app, any combination of up to 40 attributes and metrics per custom event, and any number of attribute or metric values.
  ## 
  let valid = call_601864.validator(path, query, header, formData, body)
  let scheme = call_601864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601864.url(scheme.get, call_601864.host, call_601864.base,
                         call_601864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601864, url, valid)

proc call*(call_601935: Call_PutEvents_601718; body: JsonNode): Recallable =
  ## putEvents
  ## The PutEvents operation records one or more events. You can have up to 1,500 unique custom events per app, any combination of up to 40 attributes and metrics per custom event, and any number of attribute or metric values.
  ##   body: JObject (required)
  var body_601936 = newJObject()
  if body != nil:
    body_601936 = body
  result = call_601935.call(nil, nil, nil, nil, body_601936)

var putEvents* = Call_PutEvents_601718(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "mobileanalytics.amazonaws.com", route: "/2014-06-05/events#x-amz-Client-Context",
                                    validator: validate_PutEvents_601719,
                                    base: "/", url: url_PutEvents_601720,
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
