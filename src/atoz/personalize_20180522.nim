
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCampaign_592703 = ref object of OpenApiRestCall_592364
proc url_CreateCampaign_592705(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCampaign_592704(path: JsonNode; query: JsonNode;
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateCampaign"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_CreateCampaign_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a campaign by deploying a solution version. When a client calls the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> and <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html">GetPersonalizedRanking</a> APIs, a campaign is specified in the request.</p> <p> <b>Minimum Provisioned TPS and Auto-Scaling</b> </p> <p>A transaction is a single <code>GetRecommendations</code> or <code>GetPersonalizedRanking</code> call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (<code>minProvisionedTPS</code>) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond <code>minProvisionedTPS</code>, Amazon Personalize auto-scales the provisioned capacity up and down, but never below <code>minProvisionedTPS</code>, to maintain a 70% utilization. There's a short time delay while the capacity is increased that might cause loss of transactions. It's recommended to start with a low <code>minProvisionedTPS</code>, track your usage using Amazon CloudWatch metrics, and then increase the <code>minProvisionedTPS</code> as necessary.</p> <p> <b>Status</b> </p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the campaign status, call <a>DescribeCampaign</a>.</p> <note> <p>Wait until the <code>status</code> of the campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListCampaigns</a> </p> </li> <li> <p> <a>DescribeCampaign</a> </p> </li> <li> <p> <a>UpdateCampaign</a> </p> </li> <li> <p> <a>DeleteCampaign</a> </p> </li> </ul>
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_CreateCampaign_592703; body: JsonNode): Recallable =
  ## createCampaign
  ## <p>Creates a campaign by deploying a solution version. When a client calls the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> and <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html">GetPersonalizedRanking</a> APIs, a campaign is specified in the request.</p> <p> <b>Minimum Provisioned TPS and Auto-Scaling</b> </p> <p>A transaction is a single <code>GetRecommendations</code> or <code>GetPersonalizedRanking</code> call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (<code>minProvisionedTPS</code>) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond <code>minProvisionedTPS</code>, Amazon Personalize auto-scales the provisioned capacity up and down, but never below <code>minProvisionedTPS</code>, to maintain a 70% utilization. There's a short time delay while the capacity is increased that might cause loss of transactions. It's recommended to start with a low <code>minProvisionedTPS</code>, track your usage using Amazon CloudWatch metrics, and then increase the <code>minProvisionedTPS</code> as necessary.</p> <p> <b>Status</b> </p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the campaign status, call <a>DescribeCampaign</a>.</p> <note> <p>Wait until the <code>status</code> of the campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListCampaigns</a> </p> </li> <li> <p> <a>DescribeCampaign</a> </p> </li> <li> <p> <a>UpdateCampaign</a> </p> </li> <li> <p> <a>DeleteCampaign</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var createCampaign* = Call_CreateCampaign_592703(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateCampaign",
    validator: validate_CreateCampaign_592704, base: "/", url: url_CreateCampaign_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataset_592972 = ref object of OpenApiRestCall_592364
proc url_CreateDataset_592974(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataset_592973(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDataset"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_CreateDataset_592972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an empty dataset and adds it to the specified dataset group. Use <a>CreateDatasetImportJob</a> to import your training data to a dataset.</p> <p>There are three types of datasets:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>Each dataset type has an associated schema with required field types. Only the <code>Interactions</code> dataset is required in order to train a model (also referred to as creating a solution).</p> <p>A dataset can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the dataset, call <a>DescribeDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>CreateDatasetGroup</a> </p> </li> <li> <p> <a>ListDatasets</a> </p> </li> <li> <p> <a>DescribeDataset</a> </p> </li> <li> <p> <a>DeleteDataset</a> </p> </li> </ul>
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_CreateDataset_592972; body: JsonNode): Recallable =
  ## createDataset
  ## <p>Creates an empty dataset and adds it to the specified dataset group. Use <a>CreateDatasetImportJob</a> to import your training data to a dataset.</p> <p>There are three types of datasets:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>Each dataset type has an associated schema with required field types. Only the <code>Interactions</code> dataset is required in order to train a model (also referred to as creating a solution).</p> <p>A dataset can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the dataset, call <a>DescribeDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>CreateDatasetGroup</a> </p> </li> <li> <p> <a>ListDatasets</a> </p> </li> <li> <p> <a>DescribeDataset</a> </p> </li> <li> <p> <a>DeleteDataset</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var createDataset* = Call_CreateDataset_592972(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDataset",
    validator: validate_CreateDataset_592973, base: "/", url: url_CreateDataset_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetGroup_592987 = ref object of OpenApiRestCall_592364
proc url_CreateDatasetGroup_592989(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatasetGroup_592988(path: JsonNode; query: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDatasetGroup"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_CreateDatasetGroup_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an empty dataset group. A dataset group contains related datasets that supply data for training a model. A dataset group can contain at most three datasets, one for each type of dataset:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>To train a model (create a solution), a dataset group that contains an <code>Interactions</code> dataset is required. Call <a>CreateDataset</a> to add a dataset to the group.</p> <p>A dataset group can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING</p> </li> </ul> <p>To get the status of the dataset group, call <a>DescribeDatasetGroup</a>. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the creation failed.</p> <note> <p>You must wait until the <code>status</code> of the dataset group is <code>ACTIVE</code> before adding a dataset to the group.</p> </note> <p>You can specify an AWS Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an AWS Identity and Access Management (IAM) role that has permission to access the key.</p> <p class="title"> <b>APIs that require a dataset group ARN in the request</b> </p> <ul> <li> <p> <a>CreateDataset</a> </p> </li> <li> <p> <a>CreateEventTracker</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> </ul> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetGroups</a> </p> </li> <li> <p> <a>DescribeDatasetGroup</a> </p> </li> <li> <p> <a>DeleteDatasetGroup</a> </p> </li> </ul>
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_CreateDatasetGroup_592987; body: JsonNode): Recallable =
  ## createDatasetGroup
  ## <p>Creates an empty dataset group. A dataset group contains related datasets that supply data for training a model. A dataset group can contain at most three datasets, one for each type of dataset:</p> <ul> <li> <p>Interactions</p> </li> <li> <p>Items</p> </li> <li> <p>Users</p> </li> </ul> <p>To train a model (create a solution), a dataset group that contains an <code>Interactions</code> dataset is required. Call <a>CreateDataset</a> to add a dataset to the group.</p> <p>A dataset group can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING</p> </li> </ul> <p>To get the status of the dataset group, call <a>DescribeDatasetGroup</a>. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the creation failed.</p> <note> <p>You must wait until the <code>status</code> of the dataset group is <code>ACTIVE</code> before adding a dataset to the group.</p> </note> <p>You can specify an AWS Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an AWS Identity and Access Management (IAM) role that has permission to access the key.</p> <p class="title"> <b>APIs that require a dataset group ARN in the request</b> </p> <ul> <li> <p> <a>CreateDataset</a> </p> </li> <li> <p> <a>CreateEventTracker</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> </ul> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetGroups</a> </p> </li> <li> <p> <a>DescribeDatasetGroup</a> </p> </li> <li> <p> <a>DeleteDatasetGroup</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var createDatasetGroup* = Call_CreateDatasetGroup_592987(
    name: "createDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDatasetGroup",
    validator: validate_CreateDatasetGroup_592988, base: "/",
    url: url_CreateDatasetGroup_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetImportJob_593002 = ref object of OpenApiRestCall_592364
proc url_CreateDatasetImportJob_593004(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatasetImportJob_593003(path: JsonNode; query: JsonNode;
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateDatasetImportJob"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_CreateDatasetImportJob_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an AWS Identity and Access Management (IAM) role that has permission to read from the data source.</p> <important> <p>The dataset import job replaces any previous data in the dataset.</p> </important> <p> <b>Status</b> </p> <p>A dataset import job can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the import job, call <a>DescribeDatasetImportJob</a>, providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <note> <p>Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetImportJobs</a> </p> </li> <li> <p> <a>DescribeDatasetImportJob</a> </p> </li> </ul>
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_CreateDatasetImportJob_593002; body: JsonNode): Recallable =
  ## createDatasetImportJob
  ## <p>Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an AWS Identity and Access Management (IAM) role that has permission to read from the data source.</p> <important> <p>The dataset import job replaces any previous data in the dataset.</p> </important> <p> <b>Status</b> </p> <p>A dataset import job can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the import job, call <a>DescribeDatasetImportJob</a>, providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <note> <p>Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListDatasetImportJobs</a> </p> </li> <li> <p> <a>DescribeDatasetImportJob</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var createDatasetImportJob* = Call_CreateDatasetImportJob_593002(
    name: "createDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateDatasetImportJob",
    validator: validate_CreateDatasetImportJob_593003, base: "/",
    url: url_CreateDatasetImportJob_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventTracker_593017 = ref object of OpenApiRestCall_592364
proc url_CreateEventTracker_593019(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEventTracker_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateEventTracker"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_CreateEventTracker_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an event tracker that you use when sending event data to the specified dataset group using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html">PutEvents</a> API.</p> <p>When Amazon Personalize creates an event tracker, it also creates an <i>event-interactions</i> dataset in the dataset group associated with the event tracker. The event-interactions dataset stores the event data from the <code>PutEvents</code> call. The contents of this dataset are not available to the user.</p> <note> <p>Only one event tracker can be associated with a dataset group. You will get an error if you call <code>CreateEventTracker</code> using the same dataset group as an existing event tracker.</p> </note> <p>When you send event data you include your tracking ID. The tracking ID identifies the customer and authorizes the customer to send the data.</p> <p>The event tracker can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the event tracker, call <a>DescribeEventTracker</a>.</p> <note> <p>The event tracker must be in the ACTIVE state before using the tracking ID.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListEventTrackers</a> </p> </li> <li> <p> <a>DescribeEventTracker</a> </p> </li> <li> <p> <a>DeleteEventTracker</a> </p> </li> </ul>
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_CreateEventTracker_593017; body: JsonNode): Recallable =
  ## createEventTracker
  ## <p>Creates an event tracker that you use when sending event data to the specified dataset group using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html">PutEvents</a> API.</p> <p>When Amazon Personalize creates an event tracker, it also creates an <i>event-interactions</i> dataset in the dataset group associated with the event tracker. The event-interactions dataset stores the event data from the <code>PutEvents</code> call. The contents of this dataset are not available to the user.</p> <note> <p>Only one event tracker can be associated with a dataset group. You will get an error if you call <code>CreateEventTracker</code> using the same dataset group as an existing event tracker.</p> </note> <p>When you send event data you include your tracking ID. The tracking ID identifies the customer and authorizes the customer to send the data.</p> <p>The event tracker can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the event tracker, call <a>DescribeEventTracker</a>.</p> <note> <p>The event tracker must be in the ACTIVE state before using the tracking ID.</p> </note> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListEventTrackers</a> </p> </li> <li> <p> <a>DescribeEventTracker</a> </p> </li> <li> <p> <a>DeleteEventTracker</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var createEventTracker* = Call_CreateEventTracker_593017(
    name: "createEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateEventTracker",
    validator: validate_CreateEventTracker_593018, base: "/",
    url: url_CreateEventTracker_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_593032 = ref object of OpenApiRestCall_592364
proc url_CreateSchema_593034(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSchema_593033(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSchema"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_CreateSchema_593032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format.</p> <p>Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. You specify a schema when you call <a>CreateDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSchemas</a> </p> </li> <li> <p> <a>DescribeSchema</a> </p> </li> <li> <p> <a>DeleteSchema</a> </p> </li> </ul>
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_CreateSchema_593032; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format.</p> <p>Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. You specify a schema when you call <a>CreateDataset</a>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSchemas</a> </p> </li> <li> <p> <a>DescribeSchema</a> </p> </li> <li> <p> <a>DeleteSchema</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var createSchema* = Call_CreateSchema_593032(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSchema",
    validator: validate_CreateSchema_593033, base: "/", url: url_CreateSchema_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSolution_593047 = ref object of OpenApiRestCall_592364
proc url_CreateSolution_593049(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSolution_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSolution"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_CreateSolution_593047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the <a>CreateSolutionVersion</a> operation. Every time you call <code>CreateSolutionVersion</code>, a new version of the solution is created.</p> <p>After creating a solution version, you check its accuracy by calling <a>GetSolutionMetrics</a>. When you are satisfied with the version, you deploy it using <a>CreateCampaign</a>. The campaign provides recommendations to a client through the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p> <p>To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify <code>performAutoML</code> and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you.</p> <p> <b>Status</b> </p> <p>A solution can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the solution, call <a>DescribeSolution</a>. Wait until the status shows as ACTIVE before calling <code>CreateSolutionVersion</code>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolutionVersion</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul>
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_CreateSolution_593047; body: JsonNode): Recallable =
  ## createSolution
  ## <p>Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the <a>CreateSolutionVersion</a> operation. Every time you call <code>CreateSolutionVersion</code>, a new version of the solution is created.</p> <p>After creating a solution version, you check its accuracy by calling <a>GetSolutionMetrics</a>. When you are satisfied with the version, you deploy it using <a>CreateCampaign</a>. The campaign provides recommendations to a client through the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p> <p>To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify <code>performAutoML</code> and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you.</p> <p> <b>Status</b> </p> <p>A solution can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>To get the status of the solution, call <a>DescribeSolution</a>. Wait until the status shows as ACTIVE before calling <code>CreateSolutionVersion</code>.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolutionVersion</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var createSolution* = Call_CreateSolution_593047(name: "createSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSolution",
    validator: validate_CreateSolution_593048, base: "/", url: url_CreateSolution_593049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSolutionVersion_593062 = ref object of OpenApiRestCall_592364
proc url_CreateSolutionVersion_593064(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSolutionVersion_593063(path: JsonNode; query: JsonNode;
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
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString(
      "AmazonPersonalize.CreateSolutionVersion"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_CreateSolutionVersion_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Trains or retrains an active solution. A solution is created using the <a>CreateSolution</a> operation and must be in the ACTIVE state before calling <code>CreateSolutionVersion</code>. A new version of the solution is created every time you call this operation.</p> <p> <b>Status</b> </p> <p>A solution version can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the version, call <a>DescribeSolutionVersion</a>. Wait until the status shows as ACTIVE before calling <code>CreateCampaign</code>.</p> <p>If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul>
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_CreateSolutionVersion_593062; body: JsonNode): Recallable =
  ## createSolutionVersion
  ## <p>Trains or retrains an active solution. A solution is created using the <a>CreateSolution</a> operation and must be in the ACTIVE state before calling <code>CreateSolutionVersion</code>. A new version of the solution is created every time you call this operation.</p> <p> <b>Status</b> </p> <p>A solution version can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> </ul> <p>To get the status of the version, call <a>DescribeSolutionVersion</a>. Wait until the status shows as ACTIVE before calling <code>CreateCampaign</code>.</p> <p>If the status shows as CREATE FAILED, the response includes a <code>failureReason</code> key, which describes why the job failed.</p> <p class="title"> <b>Related APIs</b> </p> <ul> <li> <p> <a>ListSolutionVersions</a> </p> </li> <li> <p> <a>DescribeSolutionVersion</a> </p> </li> </ul> <ul> <li> <p> <a>ListSolutions</a> </p> </li> <li> <p> <a>CreateSolution</a> </p> </li> <li> <p> <a>DescribeSolution</a> </p> </li> <li> <p> <a>DeleteSolution</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var createSolutionVersion* = Call_CreateSolutionVersion_593062(
    name: "createSolutionVersion", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.CreateSolutionVersion",
    validator: validate_CreateSolutionVersion_593063, base: "/",
    url: url_CreateSolutionVersion_593064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_593077 = ref object of OpenApiRestCall_592364
proc url_DeleteCampaign_593079(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCampaign_593078(path: JsonNode; query: JsonNode;
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
  var valid_593080 = header.getOrDefault("X-Amz-Target")
  valid_593080 = validateParameter(valid_593080, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteCampaign"))
  if valid_593080 != nil:
    section.add "X-Amz-Target", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_DeleteCampaign_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> request. For more information on campaigns, see <a>CreateCampaign</a>.
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_DeleteCampaign_593077; body: JsonNode): Recallable =
  ## deleteCampaign
  ## Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> request. For more information on campaigns, see <a>CreateCampaign</a>.
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var deleteCampaign* = Call_DeleteCampaign_593077(name: "deleteCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteCampaign",
    validator: validate_DeleteCampaign_593078, base: "/", url: url_DeleteCampaign_593079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_593092 = ref object of OpenApiRestCall_592364
proc url_DeleteDataset_593094(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDataset_593093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593095 = header.getOrDefault("X-Amz-Target")
  valid_593095 = validateParameter(valid_593095, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteDataset"))
  if valid_593095 != nil:
    section.add "X-Amz-Target", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Signature")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Signature", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Content-Sha256", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Date")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Date", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Credential")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Credential", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Security-Token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Security-Token", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Algorithm")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Algorithm", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-SignedHeaders", valid_593102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_DeleteDataset_593092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset. You can't delete a dataset if an associated <code>DatasetImportJob</code> or <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_DeleteDataset_593092; body: JsonNode): Recallable =
  ## deleteDataset
  ## Deletes a dataset. You can't delete a dataset if an associated <code>DatasetImportJob</code> or <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see <a>CreateDataset</a>.
  ##   body: JObject (required)
  var body_593106 = newJObject()
  if body != nil:
    body_593106 = body
  result = call_593105.call(nil, nil, nil, nil, body_593106)

var deleteDataset* = Call_DeleteDataset_593092(name: "deleteDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteDataset",
    validator: validate_DeleteDataset_593093, base: "/", url: url_DeleteDataset_593094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetGroup_593107 = ref object of OpenApiRestCall_592364
proc url_DeleteDatasetGroup_593109(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDatasetGroup_593108(path: JsonNode; query: JsonNode;
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
  var valid_593110 = header.getOrDefault("X-Amz-Target")
  valid_593110 = validateParameter(valid_593110, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteDatasetGroup"))
  if valid_593110 != nil:
    section.add "X-Amz-Target", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Algorithm")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Algorithm", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-SignedHeaders", valid_593117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593119: Call_DeleteDatasetGroup_593107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a dataset group. Before you delete a dataset group, you must delete the following:</p> <ul> <li> <p>All associated event trackers.</p> </li> <li> <p>All associated solutions.</p> </li> <li> <p>All datasets in the dataset group.</p> </li> </ul>
  ## 
  let valid = call_593119.validator(path, query, header, formData, body)
  let scheme = call_593119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593119.url(scheme.get, call_593119.host, call_593119.base,
                         call_593119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593119, url, valid)

proc call*(call_593120: Call_DeleteDatasetGroup_593107; body: JsonNode): Recallable =
  ## deleteDatasetGroup
  ## <p>Deletes a dataset group. Before you delete a dataset group, you must delete the following:</p> <ul> <li> <p>All associated event trackers.</p> </li> <li> <p>All associated solutions.</p> </li> <li> <p>All datasets in the dataset group.</p> </li> </ul>
  ##   body: JObject (required)
  var body_593121 = newJObject()
  if body != nil:
    body_593121 = body
  result = call_593120.call(nil, nil, nil, nil, body_593121)

var deleteDatasetGroup* = Call_DeleteDatasetGroup_593107(
    name: "deleteDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteDatasetGroup",
    validator: validate_DeleteDatasetGroup_593108, base: "/",
    url: url_DeleteDatasetGroup_593109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventTracker_593122 = ref object of OpenApiRestCall_592364
proc url_DeleteEventTracker_593124(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEventTracker_593123(path: JsonNode; query: JsonNode;
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
  var valid_593125 = header.getOrDefault("X-Amz-Target")
  valid_593125 = validateParameter(valid_593125, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteEventTracker"))
  if valid_593125 != nil:
    section.add "X-Amz-Target", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_DeleteEventTracker_593122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_DeleteEventTracker_593122; body: JsonNode): Recallable =
  ## deleteEventTracker
  ## Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   body: JObject (required)
  var body_593136 = newJObject()
  if body != nil:
    body_593136 = body
  result = call_593135.call(nil, nil, nil, nil, body_593136)

var deleteEventTracker* = Call_DeleteEventTracker_593122(
    name: "deleteEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteEventTracker",
    validator: validate_DeleteEventTracker_593123, base: "/",
    url: url_DeleteEventTracker_593124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_593137 = ref object of OpenApiRestCall_592364
proc url_DeleteSchema_593139(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSchema_593138(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593140 = header.getOrDefault("X-Amz-Target")
  valid_593140 = validateParameter(valid_593140, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteSchema"))
  if valid_593140 != nil:
    section.add "X-Amz-Target", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_DeleteSchema_593137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_DeleteSchema_593137; body: JsonNode): Recallable =
  ## deleteSchema
  ## Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see <a>CreateSchema</a>.
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var deleteSchema* = Call_DeleteSchema_593137(name: "deleteSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteSchema",
    validator: validate_DeleteSchema_593138, base: "/", url: url_DeleteSchema_593139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSolution_593152 = ref object of OpenApiRestCall_592364
proc url_DeleteSolution_593154(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSolution_593153(path: JsonNode; query: JsonNode;
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
  var valid_593155 = header.getOrDefault("X-Amz-Target")
  valid_593155 = validateParameter(valid_593155, JString, required = true, default = newJString(
      "AmazonPersonalize.DeleteSolution"))
  if valid_593155 != nil:
    section.add "X-Amz-Target", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_DeleteSolution_593152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all versions of a solution and the <code>Solution</code> object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call <a>ListCampaigns</a> and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_DeleteSolution_593152; body: JsonNode): Recallable =
  ## deleteSolution
  ## Deletes all versions of a solution and the <code>Solution</code> object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call <a>ListCampaigns</a> and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated <code>SolutionVersion</code> is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var deleteSolution* = Call_DeleteSolution_593152(name: "deleteSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DeleteSolution",
    validator: validate_DeleteSolution_593153, base: "/", url: url_DeleteSolution_593154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_593167 = ref object of OpenApiRestCall_592364
proc url_DescribeAlgorithm_593169(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAlgorithm_593168(path: JsonNode; query: JsonNode;
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
  var valid_593170 = header.getOrDefault("X-Amz-Target")
  valid_593170 = validateParameter(valid_593170, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeAlgorithm"))
  if valid_593170 != nil:
    section.add "X-Amz-Target", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_DescribeAlgorithm_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given algorithm.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_DescribeAlgorithm_593167; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Describes the given algorithm.
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var describeAlgorithm* = Call_DescribeAlgorithm_593167(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_593168, base: "/",
    url: url_DescribeAlgorithm_593169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCampaign_593182 = ref object of OpenApiRestCall_592364
proc url_DescribeCampaign_593184(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCampaign_593183(path: JsonNode; query: JsonNode;
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
  var valid_593185 = header.getOrDefault("X-Amz-Target")
  valid_593185 = validateParameter(valid_593185, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeCampaign"))
  if valid_593185 != nil:
    section.add "X-Amz-Target", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_DescribeCampaign_593182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the given campaign, including its status.</p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>When the <code>status</code> is <code>CREATE FAILED</code>, the response includes the <code>failureReason</code> key, which describes why.</p> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_DescribeCampaign_593182; body: JsonNode): Recallable =
  ## describeCampaign
  ## <p>Describes the given campaign, including its status.</p> <p>A campaign can be in one of the following states:</p> <ul> <li> <p>CREATE PENDING &gt; CREATE IN_PROGRESS &gt; ACTIVE -or- CREATE FAILED</p> </li> <li> <p>DELETE PENDING &gt; DELETE IN_PROGRESS</p> </li> </ul> <p>When the <code>status</code> is <code>CREATE FAILED</code>, the response includes the <code>failureReason</code> key, which describes why.</p> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ##   body: JObject (required)
  var body_593196 = newJObject()
  if body != nil:
    body_593196 = body
  result = call_593195.call(nil, nil, nil, nil, body_593196)

var describeCampaign* = Call_DescribeCampaign_593182(name: "describeCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeCampaign",
    validator: validate_DescribeCampaign_593183, base: "/",
    url: url_DescribeCampaign_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_593197 = ref object of OpenApiRestCall_592364
proc url_DescribeDataset_593199(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDataset_593198(path: JsonNode; query: JsonNode;
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
  var valid_593200 = header.getOrDefault("X-Amz-Target")
  valid_593200 = validateParameter(valid_593200, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDataset"))
  if valid_593200 != nil:
    section.add "X-Amz-Target", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593209: Call_DescribeDataset_593197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given dataset. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_DescribeDataset_593197; body: JsonNode): Recallable =
  ## describeDataset
  ## Describes the given dataset. For more information on datasets, see <a>CreateDataset</a>.
  ##   body: JObject (required)
  var body_593211 = newJObject()
  if body != nil:
    body_593211 = body
  result = call_593210.call(nil, nil, nil, nil, body_593211)

var describeDataset* = Call_DescribeDataset_593197(name: "describeDataset",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDataset",
    validator: validate_DescribeDataset_593198, base: "/", url: url_DescribeDataset_593199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetGroup_593212 = ref object of OpenApiRestCall_592364
proc url_DescribeDatasetGroup_593214(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDatasetGroup_593213(path: JsonNode; query: JsonNode;
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
  var valid_593215 = header.getOrDefault("X-Amz-Target")
  valid_593215 = validateParameter(valid_593215, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDatasetGroup"))
  if valid_593215 != nil:
    section.add "X-Amz-Target", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_DescribeDatasetGroup_593212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given dataset group. For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_DescribeDatasetGroup_593212; body: JsonNode): Recallable =
  ## describeDatasetGroup
  ## Describes the given dataset group. For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ##   body: JObject (required)
  var body_593226 = newJObject()
  if body != nil:
    body_593226 = body
  result = call_593225.call(nil, nil, nil, nil, body_593226)

var describeDatasetGroup* = Call_DescribeDatasetGroup_593212(
    name: "describeDatasetGroup", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDatasetGroup",
    validator: validate_DescribeDatasetGroup_593213, base: "/",
    url: url_DescribeDatasetGroup_593214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetImportJob_593227 = ref object of OpenApiRestCall_592364
proc url_DescribeDatasetImportJob_593229(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDatasetImportJob_593228(path: JsonNode; query: JsonNode;
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
  var valid_593230 = header.getOrDefault("X-Amz-Target")
  valid_593230 = validateParameter(valid_593230, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeDatasetImportJob"))
  if valid_593230 != nil:
    section.add "X-Amz-Target", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Signature")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Signature", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Content-Sha256", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Date")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Date", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Credential")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Credential", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Security-Token")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Security-Token", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Algorithm")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Algorithm", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-SignedHeaders", valid_593237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_DescribeDatasetImportJob_593227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the dataset import job created by <a>CreateDatasetImportJob</a>, including the import job status.
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_DescribeDatasetImportJob_593227; body: JsonNode): Recallable =
  ## describeDatasetImportJob
  ## Describes the dataset import job created by <a>CreateDatasetImportJob</a>, including the import job status.
  ##   body: JObject (required)
  var body_593241 = newJObject()
  if body != nil:
    body_593241 = body
  result = call_593240.call(nil, nil, nil, nil, body_593241)

var describeDatasetImportJob* = Call_DescribeDatasetImportJob_593227(
    name: "describeDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeDatasetImportJob",
    validator: validate_DescribeDatasetImportJob_593228, base: "/",
    url: url_DescribeDatasetImportJob_593229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTracker_593242 = ref object of OpenApiRestCall_592364
proc url_DescribeEventTracker_593244(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventTracker_593243(path: JsonNode; query: JsonNode;
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
  var valid_593245 = header.getOrDefault("X-Amz-Target")
  valid_593245 = validateParameter(valid_593245, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeEventTracker"))
  if valid_593245 != nil:
    section.add "X-Amz-Target", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Signature")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Signature", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Content-Sha256", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Date")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Date", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Credential")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Credential", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Security-Token")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Security-Token", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Algorithm")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Algorithm", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-SignedHeaders", valid_593252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593254: Call_DescribeEventTracker_593242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an event tracker. The response includes the <code>trackingId</code> and <code>status</code> of the event tracker. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_593254.validator(path, query, header, formData, body)
  let scheme = call_593254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593254.url(scheme.get, call_593254.host, call_593254.base,
                         call_593254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593254, url, valid)

proc call*(call_593255: Call_DescribeEventTracker_593242; body: JsonNode): Recallable =
  ## describeEventTracker
  ## Describes an event tracker. The response includes the <code>trackingId</code> and <code>status</code> of the event tracker. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   body: JObject (required)
  var body_593256 = newJObject()
  if body != nil:
    body_593256 = body
  result = call_593255.call(nil, nil, nil, nil, body_593256)

var describeEventTracker* = Call_DescribeEventTracker_593242(
    name: "describeEventTracker", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeEventTracker",
    validator: validate_DescribeEventTracker_593243, base: "/",
    url: url_DescribeEventTracker_593244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFeatureTransformation_593257 = ref object of OpenApiRestCall_592364
proc url_DescribeFeatureTransformation_593259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFeatureTransformation_593258(path: JsonNode; query: JsonNode;
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
  var valid_593260 = header.getOrDefault("X-Amz-Target")
  valid_593260 = validateParameter(valid_593260, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeFeatureTransformation"))
  if valid_593260 != nil:
    section.add "X-Amz-Target", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Signature")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Signature", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Content-Sha256", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Date")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Date", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Credential")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Credential", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Security-Token")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Security-Token", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Algorithm")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Algorithm", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-SignedHeaders", valid_593267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593269: Call_DescribeFeatureTransformation_593257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the given feature transformation.
  ## 
  let valid = call_593269.validator(path, query, header, formData, body)
  let scheme = call_593269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593269.url(scheme.get, call_593269.host, call_593269.base,
                         call_593269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593269, url, valid)

proc call*(call_593270: Call_DescribeFeatureTransformation_593257; body: JsonNode): Recallable =
  ## describeFeatureTransformation
  ## Describes the given feature transformation.
  ##   body: JObject (required)
  var body_593271 = newJObject()
  if body != nil:
    body_593271 = body
  result = call_593270.call(nil, nil, nil, nil, body_593271)

var describeFeatureTransformation* = Call_DescribeFeatureTransformation_593257(
    name: "describeFeatureTransformation", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeFeatureTransformation",
    validator: validate_DescribeFeatureTransformation_593258, base: "/",
    url: url_DescribeFeatureTransformation_593259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecipe_593272 = ref object of OpenApiRestCall_592364
proc url_DescribeRecipe_593274(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRecipe_593273(path: JsonNode; query: JsonNode;
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
  var valid_593275 = header.getOrDefault("X-Amz-Target")
  valid_593275 = validateParameter(valid_593275, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeRecipe"))
  if valid_593275 != nil:
    section.add "X-Amz-Target", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_DescribeRecipe_593272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a recipe.</p> <p>A recipe contains three items:</p> <ul> <li> <p>An algorithm that trains a model.</p> </li> <li> <p>Hyperparameters that govern the training.</p> </li> <li> <p>Feature transformation information for modifying the input data before training.</p> </li> </ul> <p>Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the <a>CreateSolution</a> API. <code>CreateSolution</code> trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p>
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_DescribeRecipe_593272; body: JsonNode): Recallable =
  ## describeRecipe
  ## <p>Describes a recipe.</p> <p>A recipe contains three items:</p> <ul> <li> <p>An algorithm that trains a model.</p> </li> <li> <p>Hyperparameters that govern the training.</p> </li> <li> <p>Feature transformation information for modifying the input data before training.</p> </li> </ul> <p>Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the <a>CreateSolution</a> API. <code>CreateSolution</code> trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the <a href="https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html">GetRecommendations</a> API.</p>
  ##   body: JObject (required)
  var body_593286 = newJObject()
  if body != nil:
    body_593286 = body
  result = call_593285.call(nil, nil, nil, nil, body_593286)

var describeRecipe* = Call_DescribeRecipe_593272(name: "describeRecipe",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeRecipe",
    validator: validate_DescribeRecipe_593273, base: "/", url: url_DescribeRecipe_593274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_593287 = ref object of OpenApiRestCall_592364
proc url_DescribeSchema_593289(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSchema_593288(path: JsonNode; query: JsonNode;
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
  var valid_593290 = header.getOrDefault("X-Amz-Target")
  valid_593290 = validateParameter(valid_593290, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSchema"))
  if valid_593290 != nil:
    section.add "X-Amz-Target", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Security-Token")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Security-Token", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Algorithm")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Algorithm", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-SignedHeaders", valid_593297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593299: Call_DescribeSchema_593287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a schema. For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_DescribeSchema_593287; body: JsonNode): Recallable =
  ## describeSchema
  ## Describes a schema. For more information on schemas, see <a>CreateSchema</a>.
  ##   body: JObject (required)
  var body_593301 = newJObject()
  if body != nil:
    body_593301 = body
  result = call_593300.call(nil, nil, nil, nil, body_593301)

var describeSchema* = Call_DescribeSchema_593287(name: "describeSchema",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSchema",
    validator: validate_DescribeSchema_593288, base: "/", url: url_DescribeSchema_593289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSolution_593302 = ref object of OpenApiRestCall_592364
proc url_DescribeSolution_593304(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSolution_593303(path: JsonNode; query: JsonNode;
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
  var valid_593305 = header.getOrDefault("X-Amz-Target")
  valid_593305 = validateParameter(valid_593305, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSolution"))
  if valid_593305 != nil:
    section.add "X-Amz-Target", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_DescribeSolution_593302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a solution. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_DescribeSolution_593302; body: JsonNode): Recallable =
  ## describeSolution
  ## Describes a solution. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var describeSolution* = Call_DescribeSolution_593302(name: "describeSolution",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSolution",
    validator: validate_DescribeSolution_593303, base: "/",
    url: url_DescribeSolution_593304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSolutionVersion_593317 = ref object of OpenApiRestCall_592364
proc url_DescribeSolutionVersion_593319(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSolutionVersion_593318(path: JsonNode; query: JsonNode;
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
  var valid_593320 = header.getOrDefault("X-Amz-Target")
  valid_593320 = validateParameter(valid_593320, JString, required = true, default = newJString(
      "AmazonPersonalize.DescribeSolutionVersion"))
  if valid_593320 != nil:
    section.add "X-Amz-Target", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_DescribeSolutionVersion_593317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific version of a solution. For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_DescribeSolutionVersion_593317; body: JsonNode): Recallable =
  ## describeSolutionVersion
  ## Describes a specific version of a solution. For more information on solutions, see <a>CreateSolution</a>.
  ##   body: JObject (required)
  var body_593331 = newJObject()
  if body != nil:
    body_593331 = body
  result = call_593330.call(nil, nil, nil, nil, body_593331)

var describeSolutionVersion* = Call_DescribeSolutionVersion_593317(
    name: "describeSolutionVersion", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.DescribeSolutionVersion",
    validator: validate_DescribeSolutionVersion_593318, base: "/",
    url: url_DescribeSolutionVersion_593319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSolutionMetrics_593332 = ref object of OpenApiRestCall_592364
proc url_GetSolutionMetrics_593334(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSolutionMetrics_593333(path: JsonNode; query: JsonNode;
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
  var valid_593335 = header.getOrDefault("X-Amz-Target")
  valid_593335 = validateParameter(valid_593335, JString, required = true, default = newJString(
      "AmazonPersonalize.GetSolutionMetrics"))
  if valid_593335 != nil:
    section.add "X-Amz-Target", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593344: Call_GetSolutionMetrics_593332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the metrics for the specified solution version.
  ## 
  let valid = call_593344.validator(path, query, header, formData, body)
  let scheme = call_593344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593344.url(scheme.get, call_593344.host, call_593344.base,
                         call_593344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593344, url, valid)

proc call*(call_593345: Call_GetSolutionMetrics_593332; body: JsonNode): Recallable =
  ## getSolutionMetrics
  ## Gets the metrics for the specified solution version.
  ##   body: JObject (required)
  var body_593346 = newJObject()
  if body != nil:
    body_593346 = body
  result = call_593345.call(nil, nil, nil, nil, body_593346)

var getSolutionMetrics* = Call_GetSolutionMetrics_593332(
    name: "getSolutionMetrics", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.GetSolutionMetrics",
    validator: validate_GetSolutionMetrics_593333, base: "/",
    url: url_GetSolutionMetrics_593334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCampaigns_593347 = ref object of OpenApiRestCall_592364
proc url_ListCampaigns_593349(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCampaigns_593348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593350 = query.getOrDefault("nextToken")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "nextToken", valid_593350
  var valid_593351 = query.getOrDefault("maxResults")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "maxResults", valid_593351
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
  var valid_593352 = header.getOrDefault("X-Amz-Target")
  valid_593352 = validateParameter(valid_593352, JString, required = true, default = newJString(
      "AmazonPersonalize.ListCampaigns"))
  if valid_593352 != nil:
    section.add "X-Amz-Target", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Signature")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Signature", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Content-Sha256", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Date")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Date", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Credential")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Credential", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Security-Token")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Security-Token", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Algorithm")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Algorithm", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-SignedHeaders", valid_593359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593361: Call_ListCampaigns_593347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see <a>CreateCampaign</a>.
  ## 
  let valid = call_593361.validator(path, query, header, formData, body)
  let scheme = call_593361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593361.url(scheme.get, call_593361.host, call_593361.base,
                         call_593361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593361, url, valid)

proc call*(call_593362: Call_ListCampaigns_593347; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listCampaigns
  ## Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see <a>CreateCampaign</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593363 = newJObject()
  var body_593364 = newJObject()
  add(query_593363, "nextToken", newJString(nextToken))
  if body != nil:
    body_593364 = body
  add(query_593363, "maxResults", newJString(maxResults))
  result = call_593362.call(nil, query_593363, nil, nil, body_593364)

var listCampaigns* = Call_ListCampaigns_593347(name: "listCampaigns",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListCampaigns",
    validator: validate_ListCampaigns_593348, base: "/", url: url_ListCampaigns_593349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetGroups_593366 = ref object of OpenApiRestCall_592364
proc url_ListDatasetGroups_593368(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatasetGroups_593367(path: JsonNode; query: JsonNode;
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
  var valid_593369 = query.getOrDefault("nextToken")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "nextToken", valid_593369
  var valid_593370 = query.getOrDefault("maxResults")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "maxResults", valid_593370
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
  var valid_593371 = header.getOrDefault("X-Amz-Target")
  valid_593371 = validateParameter(valid_593371, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasetGroups"))
  if valid_593371 != nil:
    section.add "X-Amz-Target", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Signature")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Signature", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Content-Sha256", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Date")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Date", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Credential")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Credential", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Security-Token")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Security-Token", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Algorithm")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Algorithm", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-SignedHeaders", valid_593378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593380: Call_ListDatasetGroups_593366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ## 
  let valid = call_593380.validator(path, query, header, formData, body)
  let scheme = call_593380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593380.url(scheme.get, call_593380.host, call_593380.base,
                         call_593380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593380, url, valid)

proc call*(call_593381: Call_ListDatasetGroups_593366; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasetGroups
  ## Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see <a>CreateDatasetGroup</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593382 = newJObject()
  var body_593383 = newJObject()
  add(query_593382, "nextToken", newJString(nextToken))
  if body != nil:
    body_593383 = body
  add(query_593382, "maxResults", newJString(maxResults))
  result = call_593381.call(nil, query_593382, nil, nil, body_593383)

var listDatasetGroups* = Call_ListDatasetGroups_593366(name: "listDatasetGroups",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasetGroups",
    validator: validate_ListDatasetGroups_593367, base: "/",
    url: url_ListDatasetGroups_593368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetImportJobs_593384 = ref object of OpenApiRestCall_592364
proc url_ListDatasetImportJobs_593386(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatasetImportJobs_593385(path: JsonNode; query: JsonNode;
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
  var valid_593387 = query.getOrDefault("nextToken")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "nextToken", valid_593387
  var valid_593388 = query.getOrDefault("maxResults")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "maxResults", valid_593388
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
  var valid_593389 = header.getOrDefault("X-Amz-Target")
  valid_593389 = validateParameter(valid_593389, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasetImportJobs"))
  if valid_593389 != nil:
    section.add "X-Amz-Target", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Signature")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Signature", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Content-Sha256", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Date")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Date", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Credential")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Credential", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Security-Token")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Security-Token", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Algorithm")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Algorithm", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-SignedHeaders", valid_593396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593398: Call_ListDatasetImportJobs_593384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see <a>CreateDatasetImportJob</a>. For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_593398.validator(path, query, header, formData, body)
  let scheme = call_593398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593398.url(scheme.get, call_593398.host, call_593398.base,
                         call_593398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593398, url, valid)

proc call*(call_593399: Call_ListDatasetImportJobs_593384; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasetImportJobs
  ## Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see <a>CreateDatasetImportJob</a>. For more information on datasets, see <a>CreateDataset</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593400 = newJObject()
  var body_593401 = newJObject()
  add(query_593400, "nextToken", newJString(nextToken))
  if body != nil:
    body_593401 = body
  add(query_593400, "maxResults", newJString(maxResults))
  result = call_593399.call(nil, query_593400, nil, nil, body_593401)

var listDatasetImportJobs* = Call_ListDatasetImportJobs_593384(
    name: "listDatasetImportJobs", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasetImportJobs",
    validator: validate_ListDatasetImportJobs_593385, base: "/",
    url: url_ListDatasetImportJobs_593386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_593402 = ref object of OpenApiRestCall_592364
proc url_ListDatasets_593404(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDatasets_593403(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593405 = query.getOrDefault("nextToken")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "nextToken", valid_593405
  var valid_593406 = query.getOrDefault("maxResults")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "maxResults", valid_593406
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
  var valid_593407 = header.getOrDefault("X-Amz-Target")
  valid_593407 = validateParameter(valid_593407, JString, required = true, default = newJString(
      "AmazonPersonalize.ListDatasets"))
  if valid_593407 != nil:
    section.add "X-Amz-Target", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Signature")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Signature", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Content-Sha256", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Date")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Date", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Credential")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Credential", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Security-Token")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Security-Token", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Algorithm")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Algorithm", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-SignedHeaders", valid_593414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593416: Call_ListDatasets_593402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see <a>CreateDataset</a>.
  ## 
  let valid = call_593416.validator(path, query, header, formData, body)
  let scheme = call_593416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593416.url(scheme.get, call_593416.host, call_593416.base,
                         call_593416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593416, url, valid)

proc call*(call_593417: Call_ListDatasets_593402; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDatasets
  ## Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see <a>CreateDataset</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593418 = newJObject()
  var body_593419 = newJObject()
  add(query_593418, "nextToken", newJString(nextToken))
  if body != nil:
    body_593419 = body
  add(query_593418, "maxResults", newJString(maxResults))
  result = call_593417.call(nil, query_593418, nil, nil, body_593419)

var listDatasets* = Call_ListDatasets_593402(name: "listDatasets",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListDatasets",
    validator: validate_ListDatasets_593403, base: "/", url: url_ListDatasets_593404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTrackers_593420 = ref object of OpenApiRestCall_592364
proc url_ListEventTrackers_593422(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventTrackers_593421(path: JsonNode; query: JsonNode;
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
  var valid_593423 = query.getOrDefault("nextToken")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "nextToken", valid_593423
  var valid_593424 = query.getOrDefault("maxResults")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "maxResults", valid_593424
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
  var valid_593425 = header.getOrDefault("X-Amz-Target")
  valid_593425 = validateParameter(valid_593425, JString, required = true, default = newJString(
      "AmazonPersonalize.ListEventTrackers"))
  if valid_593425 != nil:
    section.add "X-Amz-Target", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Signature")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Signature", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Content-Sha256", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Date")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Date", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Credential")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Credential", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Security-Token")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Security-Token", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Algorithm")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Algorithm", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-SignedHeaders", valid_593432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593434: Call_ListEventTrackers_593420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see <a>CreateEventTracker</a>.
  ## 
  let valid = call_593434.validator(path, query, header, formData, body)
  let scheme = call_593434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593434.url(scheme.get, call_593434.host, call_593434.base,
                         call_593434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593434, url, valid)

proc call*(call_593435: Call_ListEventTrackers_593420; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEventTrackers
  ## Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see <a>CreateEventTracker</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593436 = newJObject()
  var body_593437 = newJObject()
  add(query_593436, "nextToken", newJString(nextToken))
  if body != nil:
    body_593437 = body
  add(query_593436, "maxResults", newJString(maxResults))
  result = call_593435.call(nil, query_593436, nil, nil, body_593437)

var listEventTrackers* = Call_ListEventTrackers_593420(name: "listEventTrackers",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListEventTrackers",
    validator: validate_ListEventTrackers_593421, base: "/",
    url: url_ListEventTrackers_593422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecipes_593438 = ref object of OpenApiRestCall_592364
proc url_ListRecipes_593440(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRecipes_593439(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593441 = query.getOrDefault("nextToken")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "nextToken", valid_593441
  var valid_593442 = query.getOrDefault("maxResults")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "maxResults", valid_593442
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
  var valid_593443 = header.getOrDefault("X-Amz-Target")
  valid_593443 = validateParameter(valid_593443, JString, required = true, default = newJString(
      "AmazonPersonalize.ListRecipes"))
  if valid_593443 != nil:
    section.add "X-Amz-Target", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Signature")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Signature", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Content-Sha256", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Date")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Date", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Credential")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Credential", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Security-Token")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Security-Token", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Algorithm")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Algorithm", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-SignedHeaders", valid_593450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593452: Call_ListRecipes_593438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
  ## 
  let valid = call_593452.validator(path, query, header, formData, body)
  let scheme = call_593452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593452.url(scheme.get, call_593452.host, call_593452.base,
                         call_593452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593452, url, valid)

proc call*(call_593453: Call_ListRecipes_593438; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRecipes
  ## Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593454 = newJObject()
  var body_593455 = newJObject()
  add(query_593454, "nextToken", newJString(nextToken))
  if body != nil:
    body_593455 = body
  add(query_593454, "maxResults", newJString(maxResults))
  result = call_593453.call(nil, query_593454, nil, nil, body_593455)

var listRecipes* = Call_ListRecipes_593438(name: "listRecipes",
                                        meth: HttpMethod.HttpPost,
                                        host: "personalize.amazonaws.com", route: "/#X-Amz-Target=AmazonPersonalize.ListRecipes",
                                        validator: validate_ListRecipes_593439,
                                        base: "/", url: url_ListRecipes_593440,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_593456 = ref object of OpenApiRestCall_592364
proc url_ListSchemas_593458(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSchemas_593457(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593459 = query.getOrDefault("nextToken")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "nextToken", valid_593459
  var valid_593460 = query.getOrDefault("maxResults")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "maxResults", valid_593460
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
  var valid_593461 = header.getOrDefault("X-Amz-Target")
  valid_593461 = validateParameter(valid_593461, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSchemas"))
  if valid_593461 != nil:
    section.add "X-Amz-Target", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Signature")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Signature", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Content-Sha256", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Date")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Date", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Credential")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Credential", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Security-Token")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Security-Token", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Algorithm")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Algorithm", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-SignedHeaders", valid_593468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593470: Call_ListSchemas_593456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see <a>CreateSchema</a>.
  ## 
  let valid = call_593470.validator(path, query, header, formData, body)
  let scheme = call_593470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593470.url(scheme.get, call_593470.host, call_593470.base,
                         call_593470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593470, url, valid)

proc call*(call_593471: Call_ListSchemas_593456; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSchemas
  ## Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see <a>CreateSchema</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593472 = newJObject()
  var body_593473 = newJObject()
  add(query_593472, "nextToken", newJString(nextToken))
  if body != nil:
    body_593473 = body
  add(query_593472, "maxResults", newJString(maxResults))
  result = call_593471.call(nil, query_593472, nil, nil, body_593473)

var listSchemas* = Call_ListSchemas_593456(name: "listSchemas",
                                        meth: HttpMethod.HttpPost,
                                        host: "personalize.amazonaws.com", route: "/#X-Amz-Target=AmazonPersonalize.ListSchemas",
                                        validator: validate_ListSchemas_593457,
                                        base: "/", url: url_ListSchemas_593458,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSolutionVersions_593474 = ref object of OpenApiRestCall_592364
proc url_ListSolutionVersions_593476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSolutionVersions_593475(path: JsonNode; query: JsonNode;
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
  var valid_593477 = query.getOrDefault("nextToken")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "nextToken", valid_593477
  var valid_593478 = query.getOrDefault("maxResults")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "maxResults", valid_593478
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
  var valid_593479 = header.getOrDefault("X-Amz-Target")
  valid_593479 = validateParameter(valid_593479, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSolutionVersions"))
  if valid_593479 != nil:
    section.add "X-Amz-Target", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Signature")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Signature", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Content-Sha256", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Date")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Date", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Credential")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Credential", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Security-Token")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Security-Token", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Algorithm")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Algorithm", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-SignedHeaders", valid_593486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593488: Call_ListSolutionVersions_593474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_593488.validator(path, query, header, formData, body)
  let scheme = call_593488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593488.url(scheme.get, call_593488.host, call_593488.base,
                         call_593488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593488, url, valid)

proc call*(call_593489: Call_ListSolutionVersions_593474; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSolutionVersions
  ## Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593490 = newJObject()
  var body_593491 = newJObject()
  add(query_593490, "nextToken", newJString(nextToken))
  if body != nil:
    body_593491 = body
  add(query_593490, "maxResults", newJString(maxResults))
  result = call_593489.call(nil, query_593490, nil, nil, body_593491)

var listSolutionVersions* = Call_ListSolutionVersions_593474(
    name: "listSolutionVersions", meth: HttpMethod.HttpPost,
    host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListSolutionVersions",
    validator: validate_ListSolutionVersions_593475, base: "/",
    url: url_ListSolutionVersions_593476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSolutions_593492 = ref object of OpenApiRestCall_592364
proc url_ListSolutions_593494(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSolutions_593493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593495 = query.getOrDefault("nextToken")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "nextToken", valid_593495
  var valid_593496 = query.getOrDefault("maxResults")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "maxResults", valid_593496
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
  var valid_593497 = header.getOrDefault("X-Amz-Target")
  valid_593497 = validateParameter(valid_593497, JString, required = true, default = newJString(
      "AmazonPersonalize.ListSolutions"))
  if valid_593497 != nil:
    section.add "X-Amz-Target", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Signature")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Signature", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Content-Sha256", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Date")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Date", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Credential")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Credential", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Security-Token")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Security-Token", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Algorithm")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Algorithm", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-SignedHeaders", valid_593504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593506: Call_ListSolutions_593492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ## 
  let valid = call_593506.validator(path, query, header, formData, body)
  let scheme = call_593506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593506.url(scheme.get, call_593506.host, call_593506.base,
                         call_593506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593506, url, valid)

proc call*(call_593507: Call_ListSolutions_593492; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSolutions
  ## Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see <a>CreateSolution</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593508 = newJObject()
  var body_593509 = newJObject()
  add(query_593508, "nextToken", newJString(nextToken))
  if body != nil:
    body_593509 = body
  add(query_593508, "maxResults", newJString(maxResults))
  result = call_593507.call(nil, query_593508, nil, nil, body_593509)

var listSolutions* = Call_ListSolutions_593492(name: "listSolutions",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.ListSolutions",
    validator: validate_ListSolutions_593493, base: "/", url: url_ListSolutions_593494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_593510 = ref object of OpenApiRestCall_592364
proc url_UpdateCampaign_593512(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCampaign_593511(path: JsonNode; query: JsonNode;
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
  var valid_593513 = header.getOrDefault("X-Amz-Target")
  valid_593513 = validateParameter(valid_593513, JString, required = true, default = newJString(
      "AmazonPersonalize.UpdateCampaign"))
  if valid_593513 != nil:
    section.add "X-Amz-Target", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Signature")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Signature", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Content-Sha256", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Date")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Date", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Credential")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Credential", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Security-Token")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Security-Token", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Algorithm")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Algorithm", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-SignedHeaders", valid_593520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593522: Call_UpdateCampaign_593510; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a campaign by either deploying a new solution or changing the value of the campaign's <code>minProvisionedTPS</code> parameter.</p> <p>To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the <a>DescribeCampaign</a> API.</p> <note> <p>You must wait until the <code>status</code> of the updated campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ## 
  let valid = call_593522.validator(path, query, header, formData, body)
  let scheme = call_593522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593522.url(scheme.get, call_593522.host, call_593522.base,
                         call_593522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593522, url, valid)

proc call*(call_593523: Call_UpdateCampaign_593510; body: JsonNode): Recallable =
  ## updateCampaign
  ## <p>Updates a campaign by either deploying a new solution or changing the value of the campaign's <code>minProvisionedTPS</code> parameter.</p> <p>To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the <a>DescribeCampaign</a> API.</p> <note> <p>You must wait until the <code>status</code> of the updated campaign is <code>ACTIVE</code> before asking the campaign for recommendations.</p> </note> <p>For more information on campaigns, see <a>CreateCampaign</a>.</p>
  ##   body: JObject (required)
  var body_593524 = newJObject()
  if body != nil:
    body_593524 = body
  result = call_593523.call(nil, nil, nil, nil, body_593524)

var updateCampaign* = Call_UpdateCampaign_593510(name: "updateCampaign",
    meth: HttpMethod.HttpPost, host: "personalize.amazonaws.com",
    route: "/#X-Amz-Target=AmazonPersonalize.UpdateCampaign",
    validator: validate_UpdateCampaign_593511, base: "/", url: url_UpdateCampaign_593512,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
