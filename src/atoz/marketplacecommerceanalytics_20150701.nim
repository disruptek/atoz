
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Marketplace Commerce Analytics
## version: 2015-07-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides AWS Marketplace business intelligence data on-demand.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/marketplacecommerceanalytics/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "marketplacecommerceanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "marketplacecommerceanalytics.ap-southeast-1.amazonaws.com", "us-west-2": "marketplacecommerceanalytics.us-west-2.amazonaws.com", "eu-west-2": "marketplacecommerceanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "marketplacecommerceanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "marketplacecommerceanalytics.eu-central-1.amazonaws.com", "us-east-2": "marketplacecommerceanalytics.us-east-2.amazonaws.com", "us-east-1": "marketplacecommerceanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "marketplacecommerceanalytics.ap-south-1.amazonaws.com", "eu-north-1": "marketplacecommerceanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "marketplacecommerceanalytics.ap-northeast-2.amazonaws.com", "us-west-1": "marketplacecommerceanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "marketplacecommerceanalytics.us-gov-east-1.amazonaws.com", "eu-west-3": "marketplacecommerceanalytics.eu-west-3.amazonaws.com", "cn-north-1": "marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn", "sa-east-1": "marketplacecommerceanalytics.sa-east-1.amazonaws.com", "eu-west-1": "marketplacecommerceanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "marketplacecommerceanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "marketplacecommerceanalytics.ap-southeast-2.amazonaws.com", "ca-central-1": "marketplacecommerceanalytics.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {"ap-northeast-1": "marketplacecommerceanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "marketplacecommerceanalytics.ap-southeast-1.amazonaws.com",
      "us-west-2": "marketplacecommerceanalytics.us-west-2.amazonaws.com",
      "eu-west-2": "marketplacecommerceanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "marketplacecommerceanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "marketplacecommerceanalytics.eu-central-1.amazonaws.com",
      "us-east-2": "marketplacecommerceanalytics.us-east-2.amazonaws.com",
      "us-east-1": "marketplacecommerceanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "marketplacecommerceanalytics.ap-south-1.amazonaws.com",
      "eu-north-1": "marketplacecommerceanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "marketplacecommerceanalytics.ap-northeast-2.amazonaws.com",
      "us-west-1": "marketplacecommerceanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "marketplacecommerceanalytics.us-gov-east-1.amazonaws.com",
      "eu-west-3": "marketplacecommerceanalytics.eu-west-3.amazonaws.com",
      "cn-north-1": "marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "marketplacecommerceanalytics.sa-east-1.amazonaws.com",
      "eu-west-1": "marketplacecommerceanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "marketplacecommerceanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "marketplacecommerceanalytics.ap-southeast-2.amazonaws.com",
      "ca-central-1": "marketplacecommerceanalytics.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "marketplacecommerceanalytics"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GenerateDataSet_592694 = ref object of OpenApiRestCall_592355
proc url_GenerateDataSet_592696(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateDataSet_592695(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Given a data set type and data set publication date, asynchronously publishes the requested data set to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
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
  var valid_592821 = header.getOrDefault("X-Amz-Target")
  valid_592821 = validateParameter(valid_592821, JString, required = true, default = newJString(
      "MarketplaceCommerceAnalytics20150701.GenerateDataSet"))
  if valid_592821 != nil:
    section.add "X-Amz-Target", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Signature")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Signature", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Content-Sha256", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Date")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Date", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Credential")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Credential", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Security-Token")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Security-Token", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Algorithm")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Algorithm", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-SignedHeaders", valid_592828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592852: Call_GenerateDataSet_592694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a data set type and data set publication date, asynchronously publishes the requested data set to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
  ## 
  let valid = call_592852.validator(path, query, header, formData, body)
  let scheme = call_592852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592852.url(scheme.get, call_592852.host, call_592852.base,
                         call_592852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592852, url, valid)

proc call*(call_592923: Call_GenerateDataSet_592694; body: JsonNode): Recallable =
  ## generateDataSet
  ## Given a data set type and data set publication date, asynchronously publishes the requested data set to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
  ##   body: JObject (required)
  var body_592924 = newJObject()
  if body != nil:
    body_592924 = body
  result = call_592923.call(nil, nil, nil, nil, body_592924)

var generateDataSet* = Call_GenerateDataSet_592694(name: "generateDataSet",
    meth: HttpMethod.HttpPost, host: "marketplacecommerceanalytics.amazonaws.com", route: "/#X-Amz-Target=MarketplaceCommerceAnalytics20150701.GenerateDataSet",
    validator: validate_GenerateDataSet_592695, base: "/", url: url_GenerateDataSet_592696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSupportDataExport_592963 = ref object of OpenApiRestCall_592355
proc url_StartSupportDataExport_592965(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSupportDataExport_592964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Given a data set type and a from date, asynchronously publishes the requested customer support data to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD'T'HH-mm-ss'Z'.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
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
  var valid_592966 = header.getOrDefault("X-Amz-Target")
  valid_592966 = validateParameter(valid_592966, JString, required = true, default = newJString(
      "MarketplaceCommerceAnalytics20150701.StartSupportDataExport"))
  if valid_592966 != nil:
    section.add "X-Amz-Target", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Signature")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Signature", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Content-Sha256", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Date")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Date", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Credential")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Credential", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Security-Token")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Security-Token", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-Algorithm")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-Algorithm", valid_592972
  var valid_592973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-SignedHeaders", valid_592973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592975: Call_StartSupportDataExport_592963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a data set type and a from date, asynchronously publishes the requested customer support data to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD'T'HH-mm-ss'Z'.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
  ## 
  let valid = call_592975.validator(path, query, header, formData, body)
  let scheme = call_592975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592975.url(scheme.get, call_592975.host, call_592975.base,
                         call_592975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592975, url, valid)

proc call*(call_592976: Call_StartSupportDataExport_592963; body: JsonNode): Recallable =
  ## startSupportDataExport
  ## Given a data set type and a from date, asynchronously publishes the requested customer support data to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD'T'HH-mm-ss'Z'.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
  ##   body: JObject (required)
  var body_592977 = newJObject()
  if body != nil:
    body_592977 = body
  result = call_592976.call(nil, nil, nil, nil, body_592977)

var startSupportDataExport* = Call_StartSupportDataExport_592963(
    name: "startSupportDataExport", meth: HttpMethod.HttpPost,
    host: "marketplacecommerceanalytics.amazonaws.com", route: "/#X-Amz-Target=MarketplaceCommerceAnalytics20150701.StartSupportDataExport",
    validator: validate_StartSupportDataExport_592964, base: "/",
    url: url_StartSupportDataExport_592965, schemes: {Scheme.Https, Scheme.Http})
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
