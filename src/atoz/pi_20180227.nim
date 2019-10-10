
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeDimensionKeys_602794 = ref object of OpenApiRestCall_602457
proc url_DescribeDimensionKeys_602796(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDimensionKeys_602795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602908 = header.getOrDefault("X-Amz-Date")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Date", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Security-Token")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Security-Token", valid_602909
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602923 = header.getOrDefault("X-Amz-Target")
  valid_602923 = validateParameter(valid_602923, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.DescribeDimensionKeys"))
  if valid_602923 != nil:
    section.add "X-Amz-Target", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Content-Sha256", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Algorithm")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Algorithm", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Signature")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Signature", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Credential")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Credential", valid_602928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602952: Call_DescribeDimensionKeys_602794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ## 
  let valid = call_602952.validator(path, query, header, formData, body)
  let scheme = call_602952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602952.url(scheme.get, call_602952.host, call_602952.base,
                         call_602952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602952, url, valid)

proc call*(call_603023: Call_DescribeDimensionKeys_602794; body: JsonNode): Recallable =
  ## describeDimensionKeys
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ##   body: JObject (required)
  var body_603024 = newJObject()
  if body != nil:
    body_603024 = body
  result = call_603023.call(nil, nil, nil, nil, body_603024)

var describeDimensionKeys* = Call_DescribeDimensionKeys_602794(
    name: "describeDimensionKeys", meth: HttpMethod.HttpPost,
    host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.DescribeDimensionKeys",
    validator: validate_DescribeDimensionKeys_602795, base: "/",
    url: url_DescribeDimensionKeys_602796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceMetrics_603063 = ref object of OpenApiRestCall_602457
proc url_GetResourceMetrics_603065(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourceMetrics_603064(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Security-Token")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Security-Token", valid_603067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603068 = header.getOrDefault("X-Amz-Target")
  valid_603068 = validateParameter(valid_603068, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.GetResourceMetrics"))
  if valid_603068 != nil:
    section.add "X-Amz-Target", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_GetResourceMetrics_603063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ## 
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603075, url, valid)

proc call*(call_603076: Call_GetResourceMetrics_603063; body: JsonNode): Recallable =
  ## getResourceMetrics
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ##   body: JObject (required)
  var body_603077 = newJObject()
  if body != nil:
    body_603077 = body
  result = call_603076.call(nil, nil, nil, nil, body_603077)

var getResourceMetrics* = Call_GetResourceMetrics_603063(
    name: "getResourceMetrics", meth: HttpMethod.HttpPost, host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.GetResourceMetrics",
    validator: validate_GetResourceMetrics_603064, base: "/",
    url: url_GetResourceMetrics_603065, schemes: {Scheme.Https, Scheme.Http})
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
