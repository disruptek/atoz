
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Personalize
## version: 2018-05-22
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Personalize is a machine learning service that makes it easy to add individualized recommendations to customers.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/personalize/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "personalize.ap-northeast-1.amazonaws.com", "ap-southeast-1": "personalize.ap-southeast-1.amazonaws.com",
                           "us-west-2": "personalize.us-west-2.amazonaws.com",
                           "eu-west-2": "personalize.eu-west-2.amazonaws.com", "ap-northeast-3": "personalize.ap-northeast-3.amazonaws.com", "eu-central-1": "personalize.eu-central-1.amazonaws.com",
                           "us-east-2": "personalize.us-east-2.amazonaws.com",
                           "us-east-1": "personalize.us-east-1.amazonaws.com", "cn-northwest-1": "personalize.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "personalize.ap-south-1.amazonaws.com", "eu-north-1": "personalize.eu-north-1.amazonaws.com", "ap-northeast-2": "personalize.ap-northeast-2.amazonaws.com",
                           "us-west-1": "personalize.us-west-1.amazonaws.com", "us-gov-east-1": "personalize.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "personalize.eu-west-3.amazonaws.com", "cn-north-1": "personalize.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "personalize.sa-east-1.amazonaws.com",
                           "eu-west-1": "personalize.eu-west-1.amazonaws.com", "us-gov-west-1": "personalize.us-gov-west-1.amazonaws.com", "ap-southeast-2": "personalize.ap-southeast-2.amazonaws.com", "ca-central-1": "personalize.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "personalize.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "personalize.ap-southeast-1.amazonaws.com",
      "us-west-2": "personalize.us-west-2.amazonaws.com",
      "eu-west-2": "personalize.eu-west-2.amazonaws.com",
      "ap-northeast-3": "personalize.ap-northeast-3.amazonaws.com",
      "eu-central-1": "personalize.eu-central-1.amazonaws.com",
      "us-east-2": "personalize.us-east-2.amazonaws.com",
      "us-east-1": "personalize.us-east-1.amazonaws.com",
      "cn-northwest-1": "personalize.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "personalize.ap-south-1.amazonaws.com",
      "eu-north-1": "personalize.eu-north-1.amazonaws.com",
      "ap-northeast-2": "personalize.ap-northeast-2.amazonaws.com",
      "us-west-1": "personalize.us-west-1.amazonaws.com",
      "us-gov-east-1": "personalize.us-gov-east-1.amazonaws.com",
      "eu-west-3": "personalize.eu-west-3.amazonaws.com",
      "cn-north-1": "personalize.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "personalize.sa-east-1.amazonaws.com",
      "eu-west-1": "personalize.eu-west-1.amazonaws.com",
      "us-gov-west-1": "personalize.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "personalize.ap-southeast-2.amazonaws.com",
      "ca-central-1": "personalize.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "personalize"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBatchInferenceJob_605927 = ref object of OpenApiRestCall_605589
proc url_CreateBatchInferenceJob_605929(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBatchInferenceJob_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a batch inference job. The operation can handle up to 50 million records and the input file must be in JSON format. For more information, see <a>recommendations-batch</a>.
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateBatchInferenceJob"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_CreateBatchInferenceJob_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a batch inference job. The operation can handle up to 50 million records and the input file must be in JSON format. For more information, see <a>recommendations-batch</a>.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_CreateBatchInferenceJob_605927; body: JsonNode): Recallable =
  ## createBatchInferenceJob
  ## Creates a batch inference job. The operation can handle up to 50 million records and the input file must be in JSON format. For more information, see <a>recommendations-batch</a>.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var createBatchInferenceJob* = Call_CreateBatchInferenceJob_605927(
    name: "createBatchInferenceJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateBatchInferenceJob",
    validator: validate_CreateBatchInferenceJob_605928, base: "/",
    url: url_CreateBatchInferenceJob_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_606196 = ref object of OpenApiRestCall_605589
proc url_CreateCampaign_606198(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_606197(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a campaign by deploying a solution version. When a client calls the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> and <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html">GetPersonalizedRanking</a> APIs, a campaign is specified in the request.</p> <p> <b>Minimum Provisioned TPS and Auto-Scaling</b> </p> <p>A transaction is a single <code>GetRecommendations</code> or <code>GetPersonalizedRanking</code> call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (<code>minProvisionedTPS</code>) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond <code>minProvisionedTPS</code>, Amazon Personalize auto-scales the provisioned capacity up and down, but never below <code>minProvisionedTPS</code>, to maintain a 70% utilization. There's a short time delay while the capacity is increased that might cause loss of transactions. It's recommended to start with a low <code>minProvisionedTPS</code>, track your usage using Amazon CloudWatch metrics, and then increase the <code>minProvisionedTPS</code> as necessary.</p> <p> <b>Status</b> </p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the campaign status, call <a>DescribeCampaign</a>.</p> <note> <p>Wait until the <code>status</code> of the campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListCampaigns</a> </p> </li> <li> <p> <a>DescribeCampaign</a> </p> </li> <li> <p> <a>UpdateCampaign</a> </p> </li> <li> <p> <a>DeleteCampaign</a> </p> </li> </ul>
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateCampaign"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateCampaign_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a campaign by deploying a solution version. When a client calls the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> and <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html">GetPersonalizedRanking</a> APIs, a campaign is specified in the request.</p> <p> <b>Minimum Provisioned TPS and Auto-Scaling</b> </p> <p>A transaction is a single <code>GetRecommendations</code> or <code>GetPersonalizedRanking</code> call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (<code>minProvisionedTPS</code>) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond <code>minProvisionedTPS</code>, Amazon Personalize auto-scales the provisioned capacity up and down, but never below <code>minProvisionedTPS</code>, to maintain a 70% utilization. There's a short time delay while the capacity is increased that might cause loss of transactions. It's recommended to start with a low <code>minProvisionedTPS</code>, track your usage using Amazon CloudWatch metrics, and then increase the <code>minProvisionedTPS</code> as necessary.</p> <p> <b>Status</b> </p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the campaign status, call <a>DescribeCampaign</a>.</p> <note> <p>Wait until the <code>status</code> of the campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListCampaigns</a> </p> </li> <li> <p> <a>DescribeCampaign</a> </p> </li> <li> <p> <a>UpdateCampaign</a> </p> </li> <li> <p> <a>DeleteCampaign</a> </p> </li> </ul>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateCampaign_606196; body: JsonNode): Recallable =
  ## createCampaign
  ## <p>Creates a campaign by deploying a solution version. When a client calls the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> and <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html">GetPersonalizedRanking</a> APIs, a campaign is specified in the request.</p> <p> <b>Minimum Provisioned TPS and Auto-Scaling</b> </p> <p>A transaction is a single <code>GetRecommendations</code> or <code>GetPersonalizedRanking</code> call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (<code>minProvisionedTPS</code>) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond <code>minProvisionedTPS</code>, Amazon Personalize auto-scales the provisioned capacity up and down, but never below <code>minProvisionedTPS</code>, to maintain a 70% utilization. There's a short time delay while the capacity is increased that might cause loss of transactions. It's recommended to start with a low <code>minProvisionedTPS</code>, track your usage using Amazon CloudWatch metrics, and then increase the <code>minProvisionedTPS</code> as necessary.</p> <p> <b>Status</b> </p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the campaign status, call <a>DescribeCampaign</a>.</p> <note> <p>Wait until the <code>status</code> of the campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListCampaigns</a> </p> </li> <li> <p> <a>DescribeCampaign</a> </p> </li> <li> <p> <a>UpdateCampaign</a> </p> </li> <li> <p> <a>DeleteCampaign</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createCampaign* = Call_CreateCampaign_606196(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateCampaign",
    validator: validate_CreateCampaign_606197, base: "/", url: url_CreateCampaign_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_606211 = ref object of OpenApiRestCall_605589
proc url_CreateDataset_606213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataset_606212(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an empty dataset and adds it to the specified dataset group. Use <a>CreateDatasetImportJob</a> to import your training data to a dataset.</p> <p>There are three types of datasets:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>Each dataset type has an associated schema with required field types. Only the <code>Interactions</code> dataset is required in order to train a model (also referred to as creating a solution).</p> <p>A dataset can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the dataset, call <a>DescribeDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>CreateDatasetGroup</a> </p> </li> <li> <p> <a>ListDatasets</a> </p> </li> <li> <p> <a>DescribeDataset</a> </p> </li> <li> <p> <a>DeleteDataset</a> </p> </li> </ul>
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDataset"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateDataset_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an empty dataset and adds it to the specified dataset group. Use <a>CreateDatasetImportJob</a> to import your training data to a dataset.</p> <p>There are three types of datasets:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>Each dataset type has an associated schema with required field types. Only the <code>Interactions</code> dataset is required in order to train a model (also referred to as creating a solution).</p> <p>A dataset can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the dataset, call <a>DescribeDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>CreateDatasetGroup</a> </p> </li> <li> <p> <a>ListDatasets</a> </p> </li> <li> <p> <a>DescribeDataset</a> </p> </li> <li> <p> <a>DeleteDataset</a> </p> </li> </ul>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateDataset_606211; body: JsonNode): Recallable =
  ## createDataset
  ## <p>Creates an empty dataset and adds it to the specified dataset group. Use <a>CreateDatasetImportJob</a> to import your training data to a dataset.</p> <p>There are three types of datasets:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>Each dataset type has an associated schema with required field types. Only the <code>Interactions</code> dataset is required in order to train a model (also referred to as creating a solution).</p> <p>A dataset can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the dataset, call <a>DescribeDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>CreateDatasetGroup</a> </p> </li> <li> <p> <a>ListDatasets</a> </p> </li> <li> <p> <a>DescribeDataset</a> </p> </li> <li> <p> <a>DeleteDataset</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createDataset* = Call_CreateDataset_606211(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDataset",
    validator: validate_CreateDataset_606212, base: "/", url: url_CreateDataset_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetGroup_606226 = ref object of OpenApiRestCall_605589
proc url_CreateDatasetGroup_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatasetGroup_606227(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates an empty dataset group. A dataset group contains related datasets that supply data for training a model. A dataset group can contain at most three datasets, one for each type of dataset:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>To train a model (create a solution), a dataset group that contains an <code>Interactions</code> dataset is required. Call <a>CreateDataset</a> to add a dataset to the group.</p> <p>A dataset group can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING</p> </li> </ul> <p>To get the status of the dataset group, call <a>DescribeDatasetGroup</a>. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the creation failed.</p> <note> <p>You must wait until the <code>status</code> of the dataset group is <code>ACTIVE</code> before adding a dataset to the group.</p> </note> <p>You can specify an AWS Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an AWS Identity and Access Management (IAM) role that has permission to access the key.</p> <p class="title"> <b>APIs that require a dataset group ARN in the request</b> </p> <ul> <li> <p> <a>CreateDataset</a> </p> </li> <li> <p> <a>CreateEventTracker</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> </ul> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetGroups</a> </p> </li> <li> <p> <a>DescribeDatasetGroup</a> </p> </li> <li> <p> <a>DeleteDatasetGroup</a> </p> </li> </ul>
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDatasetGroup"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateDatasetGroup_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an empty dataset group. A dataset group contains related datasets that supply data for training a model. A dataset group can contain at most three datasets, one for each type of dataset:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>To train a model (create a solution), a dataset group that contains an <code>Interactions</code> dataset is required. Call <a>CreateDataset</a> to add a dataset to the group.</p> <p>A dataset group can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING</p> </li> </ul> <p>To get the status of the dataset group, call <a>DescribeDatasetGroup</a>. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the creation failed.</p> <note> <p>You must wait until the <code>status</code> of the dataset group is <code>ACTIVE</code> before adding a dataset to the group.</p> </note> <p>You can specify an AWS Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an AWS Identity and Access Management (IAM) role that has permission to access the key.</p> <p class="title"> <b>APIs that require a dataset group ARN in the request</b> </p> <ul> <li> <p> <a>CreateDataset</a> </p> </li> <li> <p> <a>CreateEventTracker</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> </ul> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetGroups</a> </p> </li> <li> <p> <a>DescribeDatasetGroup</a> </p> </li> <li> <p> <a>DeleteDatasetGroup</a> </p> </li> </ul>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateDatasetGroup_606226; body: JsonNode): Recallable =
  ## createDatasetGroup
  ## <p>Creates an empty dataset group. A dataset group contains related datasets that supply data for training a model. A dataset group can contain at most three datasets, one for each type of dataset:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>To train a model (create a solution), a dataset group that contains an <code>Interactions</code> dataset is required. Call <a>CreateDataset</a> to add a dataset to the group.</p> <p>A dataset group can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING</p> </li> </ul> <p>To get the status of the dataset group, call <a>DescribeDatasetGroup</a>. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the creation failed.</p> <note> <p>You must wait until the <code>status</code> of the dataset group is <code>ACTIVE</code> before adding a dataset to the group.</p> </note> <p>You can specify an AWS Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an AWS Identity and Access Management (IAM) role that has permission to access the key.</p> <p class="title"> <b>APIs that require a dataset group ARN in the request</b> </p> <ul> <li> <p> <a>CreateDataset</a> </p> </li> <li> <p> <a>CreateEventTracker</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> </ul> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetGroups</a> </p> </li> <li> <p> <a>DescribeDatasetGroup</a> </p> </li> <li> <p> <a>DeleteDatasetGroup</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createDatasetGroup* = Call_CreateDatasetGroup_606226(
    name: "createDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDatasetGroup",
    validator: validate_CreateDatasetGroup_606227, base: "/",
    url: url_CreateDatasetGroup_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetImportJob_606241 = ref object of OpenApiRestCall_605589
proc url_CreateDatasetImportJob_606243(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatasetImportJob_606242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an AWS Identity and Access Management (IAM) role that has permission to read from the data source.</p> <important> <p>The dataset import job replaces any previous data in the dataset.</p> </important> <p> <b>Status</b> </p> <p>A dataset import job can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the import job, call <a>DescribeDatasetImportJob</a>, providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <note> <p>Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetImportJobs</a> </p> </li> <li> <p> <a>DescribeDatasetImportJob</a> </p> </li> </ul>
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDatasetImportJob"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_CreateDatasetImportJob_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an AWS Identity and Access Management (IAM) role that has permission to read from the data source.</p> <important> <p>The dataset import job replaces any previous data in the dataset.</p> </important> <p> <b>Status</b> </p> <p>A dataset import job can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the import job, call <a>DescribeDatasetImportJob</a>, providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <note> <p>Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetImportJobs</a> </p> </li> <li> <p> <a>DescribeDatasetImportJob</a> </p> </li> </ul>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_CreateDatasetImportJob_606241; body: JsonNode): Recallable =
  ## createDatasetImportJob
  ## <p>Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an AWS Identity and Access Management (IAM) role that has permission to read from the data source.</p> <important> <p>The dataset import job replaces any previous data in the dataset.</p> </important> <p> <b>Status</b> </p> <p>A dataset import job can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the import job, call <a>DescribeDatasetImportJob</a>, providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <note> <p>Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetImportJobs</a> </p> </li> <li> <p> <a>DescribeDatasetImportJob</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var createDatasetImportJob* = Call_CreateDatasetImportJob_606241(
    name: "createDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDatasetImportJob",
    validator: validate_CreateDatasetImportJob_606242, base: "/",
    url: url_CreateDatasetImportJob_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventTracker_606256 = ref object of OpenApiRestCall_605589
proc url_CreateEventTracker_606258(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEventTracker_606257(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates an event tracker that you use when sending event data to the specified dataset group using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html">PutEvents</a> API.</p> <p>When Amazon Personalize creates an event tracker, it also creates an <i>event-interactions</i> dataset in the dataset group associated with the event tracker. The event-interactions dataset stores the event data from the <code>PutEvents</code> call. The contents of this dataset are not available to the user.</p> <note> <p>Only one event tracker can be associated with a dataset group. You will get an error if you call <code>CreateEventTracker</code> using the same dataset group as an existing event tracker.</p> </note> <p>When you send event data you include your tracking ID. The tracking ID identifies the customer and authorizes the customer to send the data.</p> <p>The event tracker can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the event tracker, call <a>DescribeEventTracker</a>.</p> <note> <p>The event tracker must be in the ACTIVE state before using the tracking ID.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListEventTrackers</a> </p> </li> <li> <p> <a>DescribeEventTracker</a> </p> </li> <li> <p> <a>DeleteEventTracker</a> </p> </li> </ul>
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateEventTracker"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_CreateEventTracker_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an event tracker that you use when sending event data to the specified dataset group using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html">PutEvents</a> API.</p> <p>When Amazon Personalize creates an event tracker, it also creates an <i>event-interactions</i> dataset in the dataset group associated with the event tracker. The event-interactions dataset stores the event data from the <code>PutEvents</code> call. The contents of this dataset are not available to the user.</p> <note> <p>Only one event tracker can be associated with a dataset group. You will get an error if you call <code>CreateEventTracker</code> using the same dataset group as an existing event tracker.</p> </note> <p>When you send event data you include your tracking ID. The tracking ID identifies the customer and authorizes the customer to send the data.</p> <p>The event tracker can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the event tracker, call <a>DescribeEventTracker</a>.</p> <note> <p>The event tracker must be in the ACTIVE state before using the tracking ID.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListEventTrackers</a> </p> </li> <li> <p> <a>DescribeEventTracker</a> </p> </li> <li> <p> <a>DeleteEventTracker</a> </p> </li> </ul>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_CreateEventTracker_606256; body: JsonNode): Recallable =
  ## createEventTracker
  ## <p>Creates an event tracker that you use when sending event data to the specified dataset group using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html">PutEvents</a> API.</p> <p>When Amazon Personalize creates an event tracker, it also creates an <i>event-interactions</i> dataset in the dataset group associated with the event tracker. The event-interactions dataset stores the event data from the <code>PutEvents</code> call. The contents of this dataset are not available to the user.</p> <note> <p>Only one event tracker can be associated with a dataset group. You will get an error if you call <code>CreateEventTracker</code> using the same dataset group as an existing event tracker.</p> </note> <p>When you send event data you include your tracking ID. The tracking ID identifies the customer and authorizes the customer to send the data.</p> <p>The event tracker can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the event tracker, call <a>DescribeEventTracker</a>.</p> <note> <p>The event tracker must be in the ACTIVE state before using the tracking ID.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListEventTrackers</a> </p> </li> <li> <p> <a>DescribeEventTracker</a> </p> </li> <li> <p> <a>DeleteEventTracker</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var createEventTracker* = Call_CreateEventTracker_606256(
    name: "createEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateEventTracker",
    validator: validate_CreateEventTracker_606257, base: "/",
    url: url_CreateEventTracker_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_606271 = ref object of OpenApiRestCall_605589
proc url_CreateSchema_606273(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_606272(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format.</p> <p>Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. You specify a schema when you call <a>CreateDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSchemas</a> </p> </li> <li> <p> <a>DescribeSchema</a> </p> </li> <li> <p> <a>DeleteSchema</a> </p> </li> </ul>
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSchema"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_CreateSchema_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format.</p> <p>Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. You specify a schema when you call <a>CreateDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSchemas</a> </p> </li> <li> <p> <a>DescribeSchema</a> </p> </li> <li> <p> <a>DeleteSchema</a> </p> </li> </ul>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_CreateSchema_606271; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format.</p> <p>Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. You specify a schema when you call <a>CreateDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSchemas</a> </p> </li> <li> <p> <a>DescribeSchema</a> </p> </li> <li> <p> <a>DeleteSchema</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var createSchema* = Call_CreateSchema_606271(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSchema",
    validator: validate_CreateSchema_606272, base: "/", url: url_CreateSchema_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSolution_606286 = ref object of OpenApiRestCall_605589
proc url_CreateSolution_606288(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSolution_606287(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the <a>CreateSolutionVersion</a> operation. Every time you call <code>CreateSolutionVersion</code>, a new version of the solution is created.</p> <p>After creating a solution version, you check its accuracy by calling <a>GetSolutionMetrics</a>. When you are satisfied with the version, you deploy it using <a>CreateCampaign</a>. The campaign provides recommendations to a client through the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p> <p>To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify <code>performAutoML</code> and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you.</p> <p> <b>Status</b> </p> <p>A solution can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the solution, call <a>DescribeSolution</a>. Wait until the status shows as ACTIVE before calling <code>CreateSolutionVersion</code>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolutionVersion</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul>
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSolution"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_CreateSolution_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the <a>CreateSolutionVersion</a> operation. Every time you call <code>CreateSolutionVersion</code>, a new version of the solution is created.</p> <p>After creating a solution version, you check its accuracy by calling <a>GetSolutionMetrics</a>. When you are satisfied with the version, you deploy it using <a>CreateCampaign</a>. The campaign provides recommendations to a client through the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p> <p>To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify <code>performAutoML</code> and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you.</p> <p> <b>Status</b> </p> <p>A solution can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the solution, call <a>DescribeSolution</a>. Wait until the status shows as ACTIVE before calling <code>CreateSolutionVersion</code>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolutionVersion</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_CreateSolution_606286; body: JsonNode): Recallable =
  ## createSolution
  ## <p>Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the <a>CreateSolutionVersion</a> operation. Every time you call <code>CreateSolutionVersion</code>, a new version of the solution is created.</p> <p>After creating a solution version, you check its accuracy by calling <a>GetSolutionMetrics</a>. When you are satisfied with the version, you deploy it using <a>CreateCampaign</a>. The campaign provides recommendations to a client through the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p> <p>To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify <code>performAutoML</code> and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you.</p> <p> <b>Status</b> </p> <p>A solution can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the solution, call <a>DescribeSolution</a>. Wait until the status shows as ACTIVE before calling <code>CreateSolutionVersion</code>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolutionVersion</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var createSolution* = Call_CreateSolution_606286(name: "createSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSolution",
    validator: validate_CreateSolution_606287, base: "/", url: url_CreateSolution_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSolutionVersion_606301 = ref object of OpenApiRestCall_605589
proc url_CreateSolutionVersion_606303(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSolutionVersion_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Trains or retrains an active solution. A solution is created using the <a>CreateSolution</a> operation and must be in the ACTIVE state before calling <code>CreateSolutionVersion</code>. A new version of the solution is created every time you call this operation.</p> <p> <b>Status</b> </p> <p>A solution version can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the version, call <a>DescribeSolutionVersion</a>. Wait until the status shows as ACTIVE before calling <code>CreateCampaign</code>.</p> <p>If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul>
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSolutionVersion"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_CreateSolutionVersion_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Trains or retrains an active solution. A solution is created using the <a>CreateSolution</a> operation and must be in the ACTIVE state before calling <code>CreateSolutionVersion</code>. A new version of the solution is created every time you call this operation.</p> <p> <b>Status</b> </p> <p>A solution version can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the version, call <a>DescribeSolutionVersion</a>. Wait until the status shows as ACTIVE before calling <code>CreateCampaign</code>.</p> <p>If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateSolutionVersion_606301; body: JsonNode): Recallable =
  ## createSolutionVersion
  ## <p>Trains or retrains an active solution. A solution is created using the <a>CreateSolution</a> operation and must be in the ACTIVE state before calling <code>CreateSolutionVersion</code>. A new version of the solution is created every time you call this operation.</p> <p> <b>Status</b> </p> <p>A solution version can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the version, call <a>DescribeSolutionVersion</a>. Wait until the status shows as ACTIVE before calling <code>CreateCampaign</code>.</p> <p>If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createSolutionVersion* = Call_CreateSolutionVersion_606301(
    name: "createSolutionVersion", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSolutionVersion",
    validator: validate_CreateSolutionVersion_606302, base: "/",
    url: url_CreateSolutionVersion_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_606316 = ref object of OpenApiRestCall_605589
proc url_DeleteCampaign_606318(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_606317(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> request. For more information on campaigns, see <a>CreateCampaign</a>.
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteCampaign"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DeleteCampaign_606316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> request. For more information on campaigns, see <a>CreateCampaign</a>.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DeleteCampaign_606316; body: JsonNode): Recallable =
  ## deleteCampaign
  ## Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> request. For more information on campaigns, see <a>CreateCampaign</a>.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var deleteCampaign* = Call_DeleteCampaign_606316(name: "deleteCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteCampaign",
    validator: validate_DeleteCampaign_606317, base: "/", url: url_DeleteCampaign_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_606331 = ref object of OpenApiRestCall_605589
proc url_DeleteDataset_606333(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_606332(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a dataset. You can't delete a dataset if an associated <code>DatasetImportJob</code> or <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see <a>CreateDataset</a>.
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteDataset"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DeleteDataset_606331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset. You can't delete a dataset if an associated <code>DatasetImportJob</code> or <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DeleteDataset_606331; body: JsonNode): Recallable =
  ## deleteDataset
  ## Deletes a dataset. You can't delete a dataset if an associated <code>DatasetImportJob</code> or <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see <a>CreateDataset</a>.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var deleteDataset* = Call_DeleteDataset_606331(name: "deleteDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteDataset",
    validator: validate_DeleteDataset_606332, base: "/", url: url_DeleteDataset_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetGroup_606346 = ref object of OpenApiRestCall_605589
proc url_DeleteDatasetGroup_606348(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatasetGroup_606347(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a dataset group. Before you delete a dataset group, you must delete the following:</p> <ul> <li> <p>All associated event trackers.</p> </li> <li> <p>All associated solutions.</p> </li> <li> <p>All datasets in the dataset group.</p> </li> </ul>
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteDatasetGroup"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_DeleteDatasetGroup_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a dataset group. Before you delete a dataset group, you must delete the following:</p> <ul> <li> <p>All associated event trackers.</p> </li> <li> <p>All associated solutions.</p> </li> <li> <p>All datasets in the dataset group.</p> </li> </ul>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_DeleteDatasetGroup_606346; body: JsonNode): Recallable =
  ## deleteDatasetGroup
  ## <p>Deletes a dataset group. Before you delete a dataset group, you must delete the following:</p> <ul> <li> <p>All associated event trackers.</p> </li> <li> <p>All associated solutions.</p> </li> <li> <p>All datasets in the dataset group.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var deleteDatasetGroup* = Call_DeleteDatasetGroup_606346(
    name: "deleteDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteDatasetGroup",
    validator: validate_DeleteDatasetGroup_606347, base: "/",
    url: url_DeleteDatasetGroup_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventTracker_606361 = ref object of OpenApiRestCall_605589
proc url_DeleteEventTracker_606363(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventTracker_606362(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see <a>CreateEventTracker</a>.
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteEventTracker"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_DeleteEventTracker_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_DeleteEventTracker_606361; body: JsonNode): Recallable =
  ## deleteEventTracker
  ## Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var deleteEventTracker* = Call_DeleteEventTracker_606361(
    name: "deleteEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteEventTracker",
    validator: validate_DeleteEventTracker_606362, base: "/",
    url: url_DeleteEventTracker_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_606376 = ref object of OpenApiRestCall_605589
proc url_DeleteSchema_606378(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_606377(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see <a>CreateSchema</a>.
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteSchema"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_DeleteSchema_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_DeleteSchema_606376; body: JsonNode): Recallable =
  ## deleteSchema
  ## Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see <a>CreateSchema</a>.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var deleteSchema* = Call_DeleteSchema_606376(name: "deleteSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteSchema",
    validator: validate_DeleteSchema_606377, base: "/", url: url_DeleteSchema_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSolution_606391 = ref object of OpenApiRestCall_605589
proc url_DeleteSolution_606393(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSolution_606392(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes all versions of a solution and the <code>Solution</code> object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call <a>ListCampaigns</a> and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see <a>CreateSolution</a>.
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteSolution"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_DeleteSolution_606391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all versions of a solution and the <code>Solution</code> object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call <a>ListCampaigns</a> and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_DeleteSolution_606391; body: JsonNode): Recallable =
  ## deleteSolution
  ## Deletes all versions of a solution and the <code>Solution</code> object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call <a>ListCampaigns</a> and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var deleteSolution* = Call_DeleteSolution_606391(name: "deleteSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteSolution",
    validator: validate_DeleteSolution_606392, base: "/", url: url_DeleteSolution_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_606406 = ref object of OpenApiRestCall_605589
proc url_DescribeAlgorithm_606408(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAlgorithm_606407(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes the given algorithm.
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
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeAlgorithm"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_DescribeAlgorithm_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given algorithm.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_DescribeAlgorithm_606406; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Describes the given algorithm.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var describeAlgorithm* = Call_DescribeAlgorithm_606406(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_606407, base: "/",
    url: url_DescribeAlgorithm_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBatchInferenceJob_606421 = ref object of OpenApiRestCall_605589
proc url_DescribeBatchInferenceJob_606423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBatchInferenceJob_606422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties of a batch inference job including name, Amazon Resource Name (ARN), status, input and output configurations, and the ARN of the solution version used to generate the recommendations.
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
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeBatchInferenceJob"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_DescribeBatchInferenceJob_606421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties of a batch inference job including name, Amazon Resource Name (ARN), status, input and output configurations, and the ARN of the solution version used to generate the recommendations.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_DescribeBatchInferenceJob_606421; body: JsonNode): Recallable =
  ## describeBatchInferenceJob
  ## Gets the properties of a batch inference job including name, Amazon Resource Name (ARN), status, input and output configurations, and the ARN of the solution version used to generate the recommendations.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var describeBatchInferenceJob* = Call_DescribeBatchInferenceJob_606421(
    name: "describeBatchInferenceJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeBatchInferenceJob",
    validator: validate_DescribeBatchInferenceJob_606422, base: "/",
    url: url_DescribeBatchInferenceJob_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCampaign_606436 = ref object of OpenApiRestCall_605589
proc url_DescribeCampaign_606438(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCampaign_606437(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Describes the given campaign, including its status.</p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>When the <code>status</code> is <code>CREATE FAILED</code>, the response includes the <code>failureReason</code> key, which describes why.</p> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeCampaign"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_DescribeCampaign_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the given campaign, including its status.</p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>When the <code>status</code> is <code>CREATE FAILED</code>, the response includes the <code>failureReason</code> key, which describes why.</p> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_DescribeCampaign_606436; body: JsonNode): Recallable =
  ## describeCampaign
  ## <p>Describes the given campaign, including its status.</p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>When the <code>status</code> is <code>CREATE FAILED</code>, the response includes the <code>failureReason</code> key, which describes why.</p> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var describeCampaign* = Call_DescribeCampaign_606436(name: "describeCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeCampaign",
    validator: validate_DescribeCampaign_606437, base: "/",
    url: url_DescribeCampaign_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_606451 = ref object of OpenApiRestCall_605589
proc url_DescribeDataset_606453(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_606452(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes the given dataset. For more information on datasets, see <a>CreateDataset</a>.
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDataset"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_DescribeDataset_606451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given dataset. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_DescribeDataset_606451; body: JsonNode): Recallable =
  ## describeDataset
  ## Describes the given dataset. For more information on datasets, see <a>CreateDataset</a>.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var describeDataset* = Call_DescribeDataset_606451(name: "describeDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDataset",
    validator: validate_DescribeDataset_606452, base: "/", url: url_DescribeDataset_606453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetGroup_606466 = ref object of OpenApiRestCall_605589
proc url_DescribeDatasetGroup_606468(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDatasetGroup_606467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the given dataset group. For more information on dataset groups, see <a>CreateDatasetGroup</a>.
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
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDatasetGroup"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_DescribeDatasetGroup_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given dataset group. For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_DescribeDatasetGroup_606466; body: JsonNode): Recallable =
  ## describeDatasetGroup
  ## Describes the given dataset group. For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var describeDatasetGroup* = Call_DescribeDatasetGroup_606466(
    name: "describeDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDatasetGroup",
    validator: validate_DescribeDatasetGroup_606467, base: "/",
    url: url_DescribeDatasetGroup_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetImportJob_606481 = ref object of OpenApiRestCall_605589
proc url_DescribeDatasetImportJob_606483(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDatasetImportJob_606482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the dataset import job created by <a>CreateDatasetImportJob</a>, including the import job status.
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
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDatasetImportJob"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_DescribeDatasetImportJob_606481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the dataset import job created by <a>CreateDatasetImportJob</a>, including the import job status.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_DescribeDatasetImportJob_606481; body: JsonNode): Recallable =
  ## describeDatasetImportJob
  ## Describes the dataset import job created by <a>CreateDatasetImportJob</a>, including the import job status.
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var describeDatasetImportJob* = Call_DescribeDatasetImportJob_606481(
    name: "describeDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDatasetImportJob",
    validator: validate_DescribeDatasetImportJob_606482, base: "/",
    url: url_DescribeDatasetImportJob_606483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTracker_606496 = ref object of OpenApiRestCall_605589
proc url_DescribeEventTracker_606498(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventTracker_606497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an event tracker. The response includes the <code>trackingId</code> and <code>status</code> of the event tracker. For more information on event trackers, see <a>CreateEventTracker</a>.
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
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeEventTracker"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_DescribeEventTracker_606496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an event tracker. The response includes the <code>trackingId</code> and <code>status</code> of the event tracker. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_DescribeEventTracker_606496; body: JsonNode): Recallable =
  ## describeEventTracker
  ## Describes an event tracker. The response includes the <code>trackingId</code> and <code>status</code> of the event tracker. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var describeEventTracker* = Call_DescribeEventTracker_606496(
    name: "describeEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeEventTracker",
    validator: validate_DescribeEventTracker_606497, base: "/",
    url: url_DescribeEventTracker_606498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFeatureTransformation_606511 = ref object of OpenApiRestCall_605589
proc url_DescribeFeatureTransformation_606513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFeatureTransformation_606512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the given feature transformation.
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
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeFeatureTransformation"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_DescribeFeatureTransformation_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given feature transformation.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_DescribeFeatureTransformation_606511; body: JsonNode): Recallable =
  ## describeFeatureTransformation
  ## Describes the given feature transformation.
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var describeFeatureTransformation* = Call_DescribeFeatureTransformation_606511(
    name: "describeFeatureTransformation", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeFeatureTransformation",
    validator: validate_DescribeFeatureTransformation_606512, base: "/",
    url: url_DescribeFeatureTransformation_606513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecipe_606526 = ref object of OpenApiRestCall_605589
proc url_DescribeRecipe_606528(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRecipe_606527(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Describes a recipe.</p> <p>A recipe contains three items:</p> <ul> <li> <p>An algorithm that trains a model.</p> </li> <li> <p>Hyperparameters that govern the training.</p> </li> <li> <p>Feature transformation information for modifying the input data before training.</p> </li> </ul> <p>Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the <a>CreateSolution</a> API. <code>CreateSolution</code> trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p>
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
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeRecipe"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DescribeRecipe_606526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a recipe.</p> <p>A recipe contains three items:</p> <ul> <li> <p>An algorithm that trains a model.</p> </li> <li> <p>Hyperparameters that govern the training.</p> </li> <li> <p>Feature transformation information for modifying the input data before training.</p> </li> </ul> <p>Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the <a>CreateSolution</a> API. <code>CreateSolution</code> trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p>
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DescribeRecipe_606526; body: JsonNode): Recallable =
  ## describeRecipe
  ## <p>Describes a recipe.</p> <p>A recipe contains three items:</p> <ul> <li> <p>An algorithm that trains a model.</p> </li> <li> <p>Hyperparameters that govern the training.</p> </li> <li> <p>Feature transformation information for modifying the input data before training.</p> </li> </ul> <p>Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the <a>CreateSolution</a> API. <code>CreateSolution</code> trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p>
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var describeRecipe* = Call_DescribeRecipe_606526(name: "describeRecipe",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeRecipe",
    validator: validate_DescribeRecipe_606527, base: "/", url: url_DescribeRecipe_606528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_606541 = ref object of OpenApiRestCall_605589
proc url_DescribeSchema_606543(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_606542(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Describes a schema. For more information on schemas, see <a>CreateSchema</a>.
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSchema"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_DescribeSchema_606541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a schema. For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_DescribeSchema_606541; body: JsonNode): Recallable =
  ## describeSchema
  ## Describes a schema. For more information on schemas, see <a>CreateSchema</a>.
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var describeSchema* = Call_DescribeSchema_606541(name: "describeSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSchema",
    validator: validate_DescribeSchema_606542, base: "/", url: url_DescribeSchema_606543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSolution_606556 = ref object of OpenApiRestCall_605589
proc url_DescribeSolution_606558(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSolution_606557(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes a solution. For more information on solutions, see <a>CreateSolution</a>.
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
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSolution"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_DescribeSolution_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a solution. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_DescribeSolution_606556; body: JsonNode): Recallable =
  ## describeSolution
  ## Describes a solution. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var describeSolution* = Call_DescribeSolution_606556(name: "describeSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSolution",
    validator: validate_DescribeSolution_606557, base: "/",
    url: url_DescribeSolution_606558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSolutionVersion_606571 = ref object of OpenApiRestCall_605589
proc url_DescribeSolutionVersion_606573(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSolutionVersion_606572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a specific version of a solution. For more information on solutions, see <a>CreateSolution</a>.
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
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSolutionVersion"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_DescribeSolutionVersion_606571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific version of a solution. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_DescribeSolutionVersion_606571; body: JsonNode): Recallable =
  ## describeSolutionVersion
  ## Describes a specific version of a solution. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_606585 = newJObject()
  if body != nil:
    body_606585 = body
  result = call_606584.call(nil, nil, nil, nil, body_606585)

var describeSolutionVersion* = Call_DescribeSolutionVersion_606571(
    name: "describeSolutionVersion", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSolutionVersion",
    validator: validate_DescribeSolutionVersion_606572, base: "/",
    url: url_DescribeSolutionVersion_606573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSolutionMetrics_606586 = ref object of OpenApiRestCall_605589
proc url_GetSolutionMetrics_606588(protocol: Scheme; host: string; base: string;
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

proc validate_GetSolutionMetrics_606587(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets the metrics for the specified solution version.
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
  var valid_606589 = header.getOrDefault("X-Amz-Target")
  valid_606589 = validateParameter(valid_606589, JString, required = true, default = newJString(
      "AmazonPersonalize.GetSolutionMetrics"))
  if valid_606589 != nil:
    section.add "X-Amz-Target", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_GetSolutionMetrics_606586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the metrics for the specified solution version.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_GetSolutionMetrics_606586; body: JsonNode): Recallable =
  ## getSolutionMetrics
  ## Gets the metrics for the specified solution version.
  ##   body: JObject (required)
  var body_606600 = newJObject()
  if body != nil:
    body_606600 = body
  result = call_606599.call(nil, nil, nil, nil, body_606600)

var getSolutionMetrics* = Call_GetSolutionMetrics_606586(
    name: "getSolutionMetrics", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.GetSolutionMetrics",
    validator: validate_GetSolutionMetrics_606587, base: "/",
    url: url_GetSolutionMetrics_606588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBatchInferenceJobs_606601 = ref object of OpenApiRestCall_605589
proc url_ListBatchInferenceJobs_606603(protocol: Scheme; host: string; base: string;
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

proc validate_ListBatchInferenceJobs_606602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the batch inference jobs that have been performed off of a solution version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606604 = query.getOrDefault("nextToken")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "nextToken", valid_606604
  var valid_606605 = query.getOrDefault("maxResults")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "maxResults", valid_606605
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
  var valid_606606 = header.getOrDefault("X-Amz-Target")
  valid_606606 = validateParameter(valid_606606, JString, required = true, default = newJString(
      "AmazonPersonalize.ListBatchInferenceJobs"))
  if valid_606606 != nil:
    section.add "X-Amz-Target", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Signature")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Signature", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Content-Sha256", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Date")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Date", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Credential")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Credential", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Security-Token")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Security-Token", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Algorithm")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Algorithm", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-SignedHeaders", valid_606613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606615: Call_ListBatchInferenceJobs_606601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the batch inference jobs that have been performed off of a solution version.
  ## 
  let valid = call_606615.validator(path, query, header, formData, body)
  let scheme = call_606615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606615.url(scheme.get, call_606615.host, call_606615.base,
                         call_606615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606615, url, valid)

proc call*(call_606616: Call_ListBatchInferenceJobs_606601; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listBatchInferenceJobs
  ## Gets a list of the batch inference jobs that have been performed off of a solution version.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606617 = newJObject()
  var body_606618 = newJObject()
  add(query_606617, "nextToken", newJString(nextToken))
  if body != nil:
    body_606618 = body
  add(query_606617, "maxResults", newJString(maxResults))
  result = call_606616.call(nil, query_606617, nil, nil, body_606618)

var listBatchInferenceJobs* = Call_ListBatchInferenceJobs_606601(
    name: "listBatchInferenceJobs", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListBatchInferenceJobs",
    validator: validate_ListBatchInferenceJobs_606602, base: "/",
    url: url_ListBatchInferenceJobs_606603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCampaigns_606620 = ref object of OpenApiRestCall_605589
proc url_ListCampaigns_606622(protocol: Scheme; host: string; base: string;
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

proc validate_ListCampaigns_606621(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see <a>CreateCampaign</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606623 = query.getOrDefault("nextToken")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "nextToken", valid_606623
  var valid_606624 = query.getOrDefault("maxResults")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "maxResults", valid_606624
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
  var valid_606625 = header.getOrDefault("X-Amz-Target")
  valid_606625 = validateParameter(valid_606625, JString, required = true, default = newJString(
      "AmazonPersonalize.ListCampaigns"))
  if valid_606625 != nil:
    section.add "X-Amz-Target", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Signature")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Signature", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Content-Sha256", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Date")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Date", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Credential")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Credential", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Security-Token")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Security-Token", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Algorithm")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Algorithm", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-SignedHeaders", valid_606632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606634: Call_ListCampaigns_606620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see <a>CreateCampaign</a>.
  ## 
  let valid = call_606634.validator(path, query, header, formData, body)
  let scheme = call_606634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606634.url(scheme.get, call_606634.host, call_606634.base,
                         call_606634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606634, url, valid)

proc call*(call_606635: Call_ListCampaigns_606620; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listCampaigns
  ## Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see <a>CreateCampaign</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606636 = newJObject()
  var body_606637 = newJObject()
  add(query_606636, "nextToken", newJString(nextToken))
  if body != nil:
    body_606637 = body
  add(query_606636, "maxResults", newJString(maxResults))
  result = call_606635.call(nil, query_606636, nil, nil, body_606637)

var listCampaigns* = Call_ListCampaigns_606620(name: "listCampaigns",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListCampaigns",
    validator: validate_ListCampaigns_606621, base: "/", url: url_ListCampaigns_606622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetGroups_606638 = ref object of OpenApiRestCall_605589
proc url_ListDatasetGroups_606640(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasetGroups_606639(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606641 = query.getOrDefault("nextToken")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "nextToken", valid_606641
  var valid_606642 = query.getOrDefault("maxResults")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "maxResults", valid_606642
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
  var valid_606643 = header.getOrDefault("X-Amz-Target")
  valid_606643 = validateParameter(valid_606643, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasetGroups"))
  if valid_606643 != nil:
    section.add "X-Amz-Target", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Signature")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Signature", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Content-Sha256", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Date")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Date", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Credential")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Credential", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Security-Token")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Security-Token", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Algorithm")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Algorithm", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-SignedHeaders", valid_606650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606652: Call_ListDatasetGroups_606638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ## 
  let valid = call_606652.validator(path, query, header, formData, body)
  let scheme = call_606652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606652.url(scheme.get, call_606652.host, call_606652.base,
                         call_606652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606652, url, valid)

proc call*(call_606653: Call_ListDatasetGroups_606638; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasetGroups
  ## Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606654 = newJObject()
  var body_606655 = newJObject()
  add(query_606654, "nextToken", newJString(nextToken))
  if body != nil:
    body_606655 = body
  add(query_606654, "maxResults", newJString(maxResults))
  result = call_606653.call(nil, query_606654, nil, nil, body_606655)

var listDatasetGroups* = Call_ListDatasetGroups_606638(name: "listDatasetGroups",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasetGroups",
    validator: validate_ListDatasetGroups_606639, base: "/",
    url: url_ListDatasetGroups_606640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetImportJobs_606656 = ref object of OpenApiRestCall_605589
proc url_ListDatasetImportJobs_606658(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasetImportJobs_606657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see <a>CreateDatasetImportJob</a>. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606659 = query.getOrDefault("nextToken")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "nextToken", valid_606659
  var valid_606660 = query.getOrDefault("maxResults")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "maxResults", valid_606660
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
  var valid_606661 = header.getOrDefault("X-Amz-Target")
  valid_606661 = validateParameter(valid_606661, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasetImportJobs"))
  if valid_606661 != nil:
    section.add "X-Amz-Target", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Signature")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Signature", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Content-Sha256", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Date")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Date", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Credential")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Credential", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Security-Token")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Security-Token", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Algorithm")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Algorithm", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-SignedHeaders", valid_606668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606670: Call_ListDatasetImportJobs_606656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see <a>CreateDatasetImportJob</a>. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_606670.validator(path, query, header, formData, body)
  let scheme = call_606670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606670.url(scheme.get, call_606670.host, call_606670.base,
                         call_606670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606670, url, valid)

proc call*(call_606671: Call_ListDatasetImportJobs_606656; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasetImportJobs
  ## Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see <a>CreateDatasetImportJob</a>. For more information on datasets, see <a>CreateDataset</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606672 = newJObject()
  var body_606673 = newJObject()
  add(query_606672, "nextToken", newJString(nextToken))
  if body != nil:
    body_606673 = body
  add(query_606672, "maxResults", newJString(maxResults))
  result = call_606671.call(nil, query_606672, nil, nil, body_606673)

var listDatasetImportJobs* = Call_ListDatasetImportJobs_606656(
    name: "listDatasetImportJobs", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasetImportJobs",
    validator: validate_ListDatasetImportJobs_606657, base: "/",
    url: url_ListDatasetImportJobs_606658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_606674 = ref object of OpenApiRestCall_605589
proc url_ListDatasets_606676(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasets_606675(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see <a>CreateDataset</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606677 = query.getOrDefault("nextToken")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "nextToken", valid_606677
  var valid_606678 = query.getOrDefault("maxResults")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "maxResults", valid_606678
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
  var valid_606679 = header.getOrDefault("X-Amz-Target")
  valid_606679 = validateParameter(valid_606679, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasets"))
  if valid_606679 != nil:
    section.add "X-Amz-Target", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_ListDatasets_606674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_ListDatasets_606674; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasets
  ## Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see <a>CreateDataset</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606690 = newJObject()
  var body_606691 = newJObject()
  add(query_606690, "nextToken", newJString(nextToken))
  if body != nil:
    body_606691 = body
  add(query_606690, "maxResults", newJString(maxResults))
  result = call_606689.call(nil, query_606690, nil, nil, body_606691)

var listDatasets* = Call_ListDatasets_606674(name: "listDatasets",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasets",
    validator: validate_ListDatasets_606675, base: "/", url: url_ListDatasets_606676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTrackers_606692 = ref object of OpenApiRestCall_605589
proc url_ListEventTrackers_606694(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventTrackers_606693(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606695 = query.getOrDefault("nextToken")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "nextToken", valid_606695
  var valid_606696 = query.getOrDefault("maxResults")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "maxResults", valid_606696
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
  var valid_606697 = header.getOrDefault("X-Amz-Target")
  valid_606697 = validateParameter(valid_606697, JString, required = true, default = newJString(
      "AmazonPersonalize.ListEventTrackers"))
  if valid_606697 != nil:
    section.add "X-Amz-Target", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Signature")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Signature", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Content-Sha256", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Date")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Date", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Credential")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Credential", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Security-Token")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Security-Token", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Algorithm")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Algorithm", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-SignedHeaders", valid_606704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606706: Call_ListEventTrackers_606692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_606706.validator(path, query, header, formData, body)
  let scheme = call_606706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606706.url(scheme.get, call_606706.host, call_606706.base,
                         call_606706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606706, url, valid)

proc call*(call_606707: Call_ListEventTrackers_606692; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEventTrackers
  ## Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606708 = newJObject()
  var body_606709 = newJObject()
  add(query_606708, "nextToken", newJString(nextToken))
  if body != nil:
    body_606709 = body
  add(query_606708, "maxResults", newJString(maxResults))
  result = call_606707.call(nil, query_606708, nil, nil, body_606709)

var listEventTrackers* = Call_ListEventTrackers_606692(name: "listEventTrackers",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListEventTrackers",
    validator: validate_ListEventTrackers_606693, base: "/",
    url: url_ListEventTrackers_606694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecipes_606710 = ref object of OpenApiRestCall_605589
proc url_ListRecipes_606712(protocol: Scheme; host: string; base: string;
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

proc validate_ListRecipes_606711(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606713 = query.getOrDefault("nextToken")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "nextToken", valid_606713
  var valid_606714 = query.getOrDefault("maxResults")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "maxResults", valid_606714
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
  var valid_606715 = header.getOrDefault("X-Amz-Target")
  valid_606715 = validateParameter(valid_606715, JString, required = true, default = newJString(
      "AmazonPersonalize.ListRecipes"))
  if valid_606715 != nil:
    section.add "X-Amz-Target", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Signature")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Signature", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Content-Sha256", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Date")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Date", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Credential")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Credential", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Security-Token")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Security-Token", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Algorithm")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Algorithm", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-SignedHeaders", valid_606722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606724: Call_ListRecipes_606710; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
  ## 
  let valid = call_606724.validator(path, query, header, formData, body)
  let scheme = call_606724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606724.url(scheme.get, call_606724.host, call_606724.base,
                         call_606724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606724, url, valid)

proc call*(call_606725: Call_ListRecipes_606710; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRecipes
  ## Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606726 = newJObject()
  var body_606727 = newJObject()
  add(query_606726, "nextToken", newJString(nextToken))
  if body != nil:
    body_606727 = body
  add(query_606726, "maxResults", newJString(maxResults))
  result = call_606725.call(nil, query_606726, nil, nil, body_606727)

var listRecipes* = Call_ListRecipes_606710(name: "listRecipes",
                                        meth: HttpMethod.HttpPost,
                                        host: "personalize.amazonaws.com", route: "/#X-Amz-Target=AmazonPersonalize.ListRecipes",
                                        validator: validate_ListRecipes_606711,
                                        base: "/", url: url_ListRecipes_606712,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_606728 = ref object of OpenApiRestCall_605589
proc url_ListSchemas_606730(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_606729(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see <a>CreateSchema</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606731 = query.getOrDefault("nextToken")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "nextToken", valid_606731
  var valid_606732 = query.getOrDefault("maxResults")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "maxResults", valid_606732
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
  var valid_606733 = header.getOrDefault("X-Amz-Target")
  valid_606733 = validateParameter(valid_606733, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSchemas"))
  if valid_606733 != nil:
    section.add "X-Amz-Target", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Signature")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Signature", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Content-Sha256", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Date")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Date", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Credential")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Credential", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Security-Token")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Security-Token", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Algorithm")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Algorithm", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-SignedHeaders", valid_606740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606742: Call_ListSchemas_606728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_606742.validator(path, query, header, formData, body)
  let scheme = call_606742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606742.url(scheme.get, call_606742.host, call_606742.base,
                         call_606742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606742, url, valid)

proc call*(call_606743: Call_ListSchemas_606728; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSchemas
  ## Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see <a>CreateSchema</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606744 = newJObject()
  var body_606745 = newJObject()
  add(query_606744, "nextToken", newJString(nextToken))
  if body != nil:
    body_606745 = body
  add(query_606744, "maxResults", newJString(maxResults))
  result = call_606743.call(nil, query_606744, nil, nil, body_606745)

var listSchemas* = Call_ListSchemas_606728(name: "listSchemas",
                                        meth: HttpMethod.HttpPost,
                                        host: "personalize.amazonaws.com", route: "/#X-Amz-Target=AmazonPersonalize.ListSchemas",
                                        validator: validate_ListSchemas_606729,
                                        base: "/", url: url_ListSchemas_606730,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSolutionVersions_606746 = ref object of OpenApiRestCall_605589
proc url_ListSolutionVersions_606748(protocol: Scheme; host: string; base: string;
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

proc validate_ListSolutionVersions_606747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606749 = query.getOrDefault("nextToken")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "nextToken", valid_606749
  var valid_606750 = query.getOrDefault("maxResults")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "maxResults", valid_606750
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
  var valid_606751 = header.getOrDefault("X-Amz-Target")
  valid_606751 = validateParameter(valid_606751, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSolutionVersions"))
  if valid_606751 != nil:
    section.add "X-Amz-Target", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Signature")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Signature", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Content-Sha256", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Date")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Date", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Credential")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Credential", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Security-Token")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Security-Token", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Algorithm")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Algorithm", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-SignedHeaders", valid_606758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606760: Call_ListSolutionVersions_606746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_606760.validator(path, query, header, formData, body)
  let scheme = call_606760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606760.url(scheme.get, call_606760.host, call_606760.base,
                         call_606760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606760, url, valid)

proc call*(call_606761: Call_ListSolutionVersions_606746; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSolutionVersions
  ## Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606762 = newJObject()
  var body_606763 = newJObject()
  add(query_606762, "nextToken", newJString(nextToken))
  if body != nil:
    body_606763 = body
  add(query_606762, "maxResults", newJString(maxResults))
  result = call_606761.call(nil, query_606762, nil, nil, body_606763)

var listSolutionVersions* = Call_ListSolutionVersions_606746(
    name: "listSolutionVersions", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListSolutionVersions",
    validator: validate_ListSolutionVersions_606747, base: "/",
    url: url_ListSolutionVersions_606748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSolutions_606764 = ref object of OpenApiRestCall_605589
proc url_ListSolutions_606766(protocol: Scheme; host: string; base: string;
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

proc validate_ListSolutions_606765(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606767 = query.getOrDefault("nextToken")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "nextToken", valid_606767
  var valid_606768 = query.getOrDefault("maxResults")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "maxResults", valid_606768
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
  var valid_606769 = header.getOrDefault("X-Amz-Target")
  valid_606769 = validateParameter(valid_606769, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSolutions"))
  if valid_606769 != nil:
    section.add "X-Amz-Target", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Signature")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Signature", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Content-Sha256", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Date")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Date", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Credential")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Credential", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Security-Token")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Security-Token", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Algorithm")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Algorithm", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-SignedHeaders", valid_606776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_ListSolutions_606764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_ListSolutions_606764; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSolutions
  ## Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606780 = newJObject()
  var body_606781 = newJObject()
  add(query_606780, "nextToken", newJString(nextToken))
  if body != nil:
    body_606781 = body
  add(query_606780, "maxResults", newJString(maxResults))
  result = call_606779.call(nil, query_606780, nil, nil, body_606781)

var listSolutions* = Call_ListSolutions_606764(name: "listSolutions",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListSolutions",
    validator: validate_ListSolutions_606765, base: "/", url: url_ListSolutions_606766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_606782 = ref object of OpenApiRestCall_605589
proc url_UpdateCampaign_606784(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_606783(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Updates a campaign by either deploying a new solution or changing the value of the campaign's <code>minProvisionedTPS</code> parameter.</p> <p>To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the <a>DescribeCampaign</a> API.</p> <note> <p>You must wait until the <code>status</code> of the updated campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
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
  var valid_606785 = header.getOrDefault("X-Amz-Target")
  valid_606785 = validateParameter(valid_606785, JString, required = true, default = newJString(
      "AmazonPersonalize.UpdateCampaign"))
  if valid_606785 != nil:
    section.add "X-Amz-Target", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Signature")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Signature", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Content-Sha256", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Date")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Date", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Credential")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Credential", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Security-Token")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Security-Token", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Algorithm")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Algorithm", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-SignedHeaders", valid_606792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606794: Call_UpdateCampaign_606782; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a campaign by either deploying a new solution or changing the value of the campaign's <code>minProvisionedTPS</code> parameter.</p> <p>To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the <a>DescribeCampaign</a> API.</p> <note> <p>You must wait until the <code>status</code> of the updated campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ## 
  let valid = call_606794.validator(path, query, header, formData, body)
  let scheme = call_606794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606794.url(scheme.get, call_606794.host, call_606794.base,
                         call_606794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606794, url, valid)

proc call*(call_606795: Call_UpdateCampaign_606782; body: JsonNode): Recallable =
  ## updateCampaign
  ## <p>Updates a campaign by either deploying a new solution or changing the value of the campaign's <code>minProvisionedTPS</code> parameter.</p> <p>To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the <a>DescribeCampaign</a> API.</p> <note> <p>You must wait until the <code>status</code> of the updated campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ##   body: JObject (required)
  var body_606796 = newJObject()
  if body != nil:
    body_606796 = body
  result = call_606795.call(nil, nil, nil, nil, body_606796)

var updateCampaign* = Call_UpdateCampaign_606782(name: "updateCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.UpdateCampaign",
    validator: validate_UpdateCampaign_606783, base: "/", url: url_UpdateCampaign_606784,
    schemes: {Scheme.Https, Scheme.Http})
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
