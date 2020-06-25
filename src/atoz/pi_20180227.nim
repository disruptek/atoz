
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Performance Insights
## version: 2018-02-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Performance Insights enables you to monitor and explore different dimensions of database load based on data captured from a running RDS instance. The guide provides detailed information about Performance Insights data types, parameters and errors. For more information about Performance Insights capabilities see <a href="http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html">Using Amazon RDS Performance Insights </a> in the <i>Amazon RDS User Guide</i>.</p> <p> The AWS Performance Insights API provides visibility into the performance of your RDS instance, when Performance Insights is enabled for supported engine types. While Amazon CloudWatch provides the authoritative source for AWS service vended monitoring metrics, AWS Performance Insights offers a domain-specific view of database load measured as Average Active Sessions and provided to API consumers as a 2-dimensional time-series dataset. The time dimension of the data provides DB load data for each time point in the queried time range, and each time point decomposes overall load in relation to the requested dimensions, such as SQL, Wait-event, User or Host, measured at that time point.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/pi/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "pi.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "pi.ap-southeast-1.amazonaws.com",
                           "us-west-2": "pi.us-west-2.amazonaws.com",
                           "eu-west-2": "pi.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "pi.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "pi.eu-central-1.amazonaws.com",
                           "us-east-2": "pi.us-east-2.amazonaws.com",
                           "us-east-1": "pi.us-east-1.amazonaws.com", "cn-northwest-1": "pi.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "pi.ap-south-1.amazonaws.com",
                           "eu-north-1": "pi.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "pi.ap-northeast-2.amazonaws.com",
                           "us-west-1": "pi.us-west-1.amazonaws.com",
                           "us-gov-east-1": "pi.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "pi.eu-west-3.amazonaws.com",
                           "cn-north-1": "pi.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "pi.sa-east-1.amazonaws.com",
                           "eu-west-1": "pi.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "pi.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "pi.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "pi.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "pi.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "pi.ap-southeast-1.amazonaws.com",
      "us-west-2": "pi.us-west-2.amazonaws.com",
      "eu-west-2": "pi.eu-west-2.amazonaws.com",
      "ap-northeast-3": "pi.ap-northeast-3.amazonaws.com",
      "eu-central-1": "pi.eu-central-1.amazonaws.com",
      "us-east-2": "pi.us-east-2.amazonaws.com",
      "us-east-1": "pi.us-east-1.amazonaws.com",
      "cn-northwest-1": "pi.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "pi.ap-south-1.amazonaws.com",
      "eu-north-1": "pi.eu-north-1.amazonaws.com",
      "ap-northeast-2": "pi.ap-northeast-2.amazonaws.com",
      "us-west-1": "pi.us-west-1.amazonaws.com",
      "us-gov-east-1": "pi.us-gov-east-1.amazonaws.com",
      "eu-west-3": "pi.eu-west-3.amazonaws.com",
      "cn-north-1": "pi.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "pi.sa-east-1.amazonaws.com",
      "eu-west-1": "pi.eu-west-1.amazonaws.com",
      "us-gov-west-1": "pi.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "pi.ap-southeast-2.amazonaws.com",
      "ca-central-1": "pi.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pi"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_DescribeDimensionKeys_21625770 = ref object of OpenApiRestCall_21625426
proc url_DescribeDimensionKeys_21625772(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDimensionKeys_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
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
  var valid_21625889 = header.getOrDefault("X-Amz-Target")
  valid_21625889 = validateParameter(valid_21625889, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.DescribeDimensionKeys"))
  if valid_21625889 != nil:
    section.add "X-Amz-Target", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Algorithm", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Signature")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Signature", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Credential")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Credential", valid_21625894
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

proc call*(call_21625920: Call_DescribeDimensionKeys_21625770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ## 
  let valid = call_21625920.validator(path, query, header, formData, body, _)
  let scheme = call_21625920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625920.makeUrl(scheme.get, call_21625920.host, call_21625920.base,
                               call_21625920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625920, uri, valid, _)

proc call*(call_21625983: Call_DescribeDimensionKeys_21625770; body: JsonNode): Recallable =
  ## describeDimensionKeys
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ##   body: JObject (required)
  var body_21625984 = newJObject()
  if body != nil:
    body_21625984 = body
  result = call_21625983.call(nil, nil, nil, nil, body_21625984)

var describeDimensionKeys* = Call_DescribeDimensionKeys_21625770(
    name: "describeDimensionKeys", meth: HttpMethod.HttpPost,
    host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.DescribeDimensionKeys",
    validator: validate_DescribeDimensionKeys_21625771, base: "/",
    makeUrl: url_DescribeDimensionKeys_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceMetrics_21626020 = ref object of OpenApiRestCall_21625426
proc url_GetResourceMetrics_21626022(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceMetrics_21626021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
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
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Target")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.GetResourceMetrics"))
  if valid_21626025 != nil:
    section.add "X-Amz-Target", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_GetResourceMetrics_21626020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_GetResourceMetrics_21626020; body: JsonNode): Recallable =
  ## getResourceMetrics
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var getResourceMetrics* = Call_GetResourceMetrics_21626020(
    name: "getResourceMetrics", meth: HttpMethod.HttpPost, host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.GetResourceMetrics",
    validator: validate_GetResourceMetrics_21626021, base: "/",
    makeUrl: url_GetResourceMetrics_21626022, schemes: {Scheme.Https, Scheme.Http})
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