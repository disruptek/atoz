
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Forecast Query Service
## version: 2018-06-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides APIs for creating and managing Amazon Forecast resources.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/forecastquery/
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

  OpenApiRestCall_602420 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602420](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602420): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "forecastquery.ap-northeast-1.amazonaws.com", "ap-southeast-1": "forecastquery.ap-southeast-1.amazonaws.com", "us-west-2": "forecastquery.us-west-2.amazonaws.com", "eu-west-2": "forecastquery.eu-west-2.amazonaws.com", "ap-northeast-3": "forecastquery.ap-northeast-3.amazonaws.com", "eu-central-1": "forecastquery.eu-central-1.amazonaws.com", "us-east-2": "forecastquery.us-east-2.amazonaws.com", "us-east-1": "forecastquery.us-east-1.amazonaws.com", "cn-northwest-1": "forecastquery.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "forecastquery.ap-south-1.amazonaws.com", "eu-north-1": "forecastquery.eu-north-1.amazonaws.com", "ap-northeast-2": "forecastquery.ap-northeast-2.amazonaws.com", "us-west-1": "forecastquery.us-west-1.amazonaws.com", "us-gov-east-1": "forecastquery.us-gov-east-1.amazonaws.com", "eu-west-3": "forecastquery.eu-west-3.amazonaws.com", "cn-north-1": "forecastquery.cn-north-1.amazonaws.com.cn", "sa-east-1": "forecastquery.sa-east-1.amazonaws.com", "eu-west-1": "forecastquery.eu-west-1.amazonaws.com", "us-gov-west-1": "forecastquery.us-gov-west-1.amazonaws.com", "ap-southeast-2": "forecastquery.ap-southeast-2.amazonaws.com", "ca-central-1": "forecastquery.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "forecastquery.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "forecastquery.ap-southeast-1.amazonaws.com",
      "us-west-2": "forecastquery.us-west-2.amazonaws.com",
      "eu-west-2": "forecastquery.eu-west-2.amazonaws.com",
      "ap-northeast-3": "forecastquery.ap-northeast-3.amazonaws.com",
      "eu-central-1": "forecastquery.eu-central-1.amazonaws.com",
      "us-east-2": "forecastquery.us-east-2.amazonaws.com",
      "us-east-1": "forecastquery.us-east-1.amazonaws.com",
      "cn-northwest-1": "forecastquery.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "forecastquery.ap-south-1.amazonaws.com",
      "eu-north-1": "forecastquery.eu-north-1.amazonaws.com",
      "ap-northeast-2": "forecastquery.ap-northeast-2.amazonaws.com",
      "us-west-1": "forecastquery.us-west-1.amazonaws.com",
      "us-gov-east-1": "forecastquery.us-gov-east-1.amazonaws.com",
      "eu-west-3": "forecastquery.eu-west-3.amazonaws.com",
      "cn-north-1": "forecastquery.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "forecastquery.sa-east-1.amazonaws.com",
      "eu-west-1": "forecastquery.eu-west-1.amazonaws.com",
      "us-gov-west-1": "forecastquery.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "forecastquery.ap-southeast-2.amazonaws.com",
      "ca-central-1": "forecastquery.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "forecastquery"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_QueryForecast_602757 = ref object of OpenApiRestCall_602420
proc url_QueryForecast_602759(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_QueryForecast_602758(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a forecast filtered by the supplied criteria.</p> <p>The criteria is a key-value pair. The key is either <code>item_id</code> (or the equivalent non-timestamp, non-target field) from the <code>TARGET_TIME_SERIES</code> dataset, or one of the forecast dimensions specified as part of the <code>FeaturizationConfig</code> object.</p> <p>By default, the complete date range of the filtered forecast is returned. Optionally, you can request a specific date range within the forecast.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same timezone as the dataset that was used to create the predictor.</p> </note>
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
  var valid_602871 = header.getOrDefault("X-Amz-Date")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Date", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Security-Token")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Security-Token", valid_602872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602886 = header.getOrDefault("X-Amz-Target")
  valid_602886 = validateParameter(valid_602886, JString, required = true, default = newJString(
      "AmazonForecastRuntime.QueryForecast"))
  if valid_602886 != nil:
    section.add "X-Amz-Target", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_QueryForecast_602757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a forecast filtered by the supplied criteria.</p> <p>The criteria is a key-value pair. The key is either <code>item_id</code> (or the equivalent non-timestamp, non-target field) from the <code>TARGET_TIME_SERIES</code> dataset, or one of the forecast dimensions specified as part of the <code>FeaturizationConfig</code> object.</p> <p>By default, the complete date range of the filtered forecast is returned. Optionally, you can request a specific date range within the forecast.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same timezone as the dataset that was used to create the predictor.</p> </note>
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"))
  result = hook(call_602915, url, valid)

proc call*(call_602986: Call_QueryForecast_602757; body: JsonNode): Recallable =
  ## queryForecast
  ## <p>Retrieves a forecast filtered by the supplied criteria.</p> <p>The criteria is a key-value pair. The key is either <code>item_id</code> (or the equivalent non-timestamp, non-target field) from the <code>TARGET_TIME_SERIES</code> dataset, or one of the forecast dimensions specified as part of the <code>FeaturizationConfig</code> object.</p> <p>By default, the complete date range of the filtered forecast is returned. Optionally, you can request a specific date range within the forecast.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same timezone as the dataset that was used to create the predictor.</p> </note>
  ##   body: JObject (required)
  var body_602987 = newJObject()
  if body != nil:
    body_602987 = body
  result = call_602986.call(nil, nil, nil, nil, body_602987)

var queryForecast* = Call_QueryForecast_602757(name: "queryForecast",
    meth: HttpMethod.HttpPost, host: "forecastquery.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecastRuntime.QueryForecast",
    validator: validate_QueryForecast_602758, base: "/", url: url_QueryForecast_602759,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
