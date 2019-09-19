
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772588 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772588](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772588): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_DescribeDimensionKeys_772924 = ref object of OpenApiRestCall_772588
proc url_DescribeDimensionKeys_772926(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDimensionKeys_772925(path: JsonNode; query: JsonNode;
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
  var valid_773038 = header.getOrDefault("X-Amz-Date")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-Date", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Security-Token")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Security-Token", valid_773039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773053 = header.getOrDefault("X-Amz-Target")
  valid_773053 = validateParameter(valid_773053, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.DescribeDimensionKeys"))
  if valid_773053 != nil:
    section.add "X-Amz-Target", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Content-Sha256", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Algorithm")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Algorithm", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-Signature")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-Signature", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-SignedHeaders", valid_773057
  var valid_773058 = header.getOrDefault("X-Amz-Credential")
  valid_773058 = validateParameter(valid_773058, JString, required = false,
                                 default = nil)
  if valid_773058 != nil:
    section.add "X-Amz-Credential", valid_773058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773082: Call_DescribeDimensionKeys_772924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ## 
  let valid = call_773082.validator(path, query, header, formData, body)
  let scheme = call_773082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773082.url(scheme.get, call_773082.host, call_773082.base,
                         call_773082.route, valid.getOrDefault("path"))
  result = hook(call_773082, url, valid)

proc call*(call_773153: Call_DescribeDimensionKeys_772924; body: JsonNode): Recallable =
  ## describeDimensionKeys
  ## For a specific time period, retrieve the top <code>N</code> dimension keys for a metric.
  ##   body: JObject (required)
  var body_773154 = newJObject()
  if body != nil:
    body_773154 = body
  result = call_773153.call(nil, nil, nil, nil, body_773154)

var describeDimensionKeys* = Call_DescribeDimensionKeys_772924(
    name: "describeDimensionKeys", meth: HttpMethod.HttpPost,
    host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.DescribeDimensionKeys",
    validator: validate_DescribeDimensionKeys_772925, base: "/",
    url: url_DescribeDimensionKeys_772926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceMetrics_773193 = ref object of OpenApiRestCall_772588
proc url_GetResourceMetrics_773195(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceMetrics_773194(path: JsonNode; query: JsonNode;
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
  var valid_773196 = header.getOrDefault("X-Amz-Date")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Date", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Security-Token")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Security-Token", valid_773197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773198 = header.getOrDefault("X-Amz-Target")
  valid_773198 = validateParameter(valid_773198, JString, required = true, default = newJString(
      "PerformanceInsightsv20180227.GetResourceMetrics"))
  if valid_773198 != nil:
    section.add "X-Amz-Target", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Content-Sha256", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-Algorithm")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-Algorithm", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Signature")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Signature", valid_773201
  var valid_773202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773202 = validateParameter(valid_773202, JString, required = false,
                                 default = nil)
  if valid_773202 != nil:
    section.add "X-Amz-SignedHeaders", valid_773202
  var valid_773203 = header.getOrDefault("X-Amz-Credential")
  valid_773203 = validateParameter(valid_773203, JString, required = false,
                                 default = nil)
  if valid_773203 != nil:
    section.add "X-Amz-Credential", valid_773203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773205: Call_GetResourceMetrics_773193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ## 
  let valid = call_773205.validator(path, query, header, formData, body)
  let scheme = call_773205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773205.url(scheme.get, call_773205.host, call_773205.base,
                         call_773205.route, valid.getOrDefault("path"))
  result = hook(call_773205, url, valid)

proc call*(call_773206: Call_GetResourceMetrics_773193; body: JsonNode): Recallable =
  ## getResourceMetrics
  ## Retrieve Performance Insights metrics for a set of data sources, over a time period. You can provide specific dimension groups and dimensions, and provide aggregation and filtering criteria for each group.
  ##   body: JObject (required)
  var body_773207 = newJObject()
  if body != nil:
    body_773207 = body
  result = call_773206.call(nil, nil, nil, nil, body_773207)

var getResourceMetrics* = Call_GetResourceMetrics_773193(
    name: "getResourceMetrics", meth: HttpMethod.HttpPost, host: "pi.amazonaws.com",
    route: "/#X-Amz-Target=PerformanceInsightsv20180227.GetResourceMetrics",
    validator: validate_GetResourceMetrics_773194, base: "/",
    url: url_GetResourceMetrics_773195, schemes: {Scheme.Https, Scheme.Http})
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
