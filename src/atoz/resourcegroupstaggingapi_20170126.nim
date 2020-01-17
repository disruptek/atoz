
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Groups Tagging API
## version: 2017-01-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Resource Groups Tagging API</fullname> <p>This guide describes the API operations for the resource groups tagging.</p> <p>A tag is a label that you assign to an AWS resource. A tag consists of a key and a value, both of which you define. For example, if you have two Amazon EC2 instances, you might assign both a tag key of "Stack." But the value of "Stack" might be "Testing" for one and "Production" for the other.</p> <p>Tagging can help you organize your resources and enables you to simplify resource management, access management and cost allocation. </p> <p>You can use the resource groups tagging API operations to complete the following tasks:</p> <ul> <li> <p>Tag and untag supported resources located in the specified Region for the AWS account.</p> </li> <li> <p>Use tag-based filters to search for resources located in the specified Region for the AWS account.</p> </li> <li> <p>List all existing tag keys in the specified Region for the AWS account.</p> </li> <li> <p>List all existing values for the specified key in the specified Region for the AWS account.</p> </li> </ul> <p>To use resource groups tagging API operations, you must add the following permissions to your IAM policy:</p> <ul> <li> <p> <code>tag:GetResources</code> </p> </li> <li> <p> <code>tag:TagResources</code> </p> </li> <li> <p> <code>tag:UntagResources</code> </p> </li> <li> <p> <code>tag:GetTagKeys</code> </p> </li> <li> <p> <code>tag:GetTagValues</code> </p> </li> </ul> <p>You'll also need permissions to access the resources of individual services so that you can tag and untag those resources.</p> <p>For more information on IAM policies, see <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage.html">Managing IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p>You can use the Resource Groups Tagging API to tag resources for the following AWS services.</p> <ul> <li> <p>Alexa for Business (a4b)</p> </li> <li> <p>API Gateway</p> </li> <li> <p>Amazon AppStream</p> </li> <li> <p>AWS AppSync</p> </li> <li> <p>AWS App Mesh</p> </li> <li> <p>Amazon Athena</p> </li> <li> <p>Amazon Aurora</p> </li> <li> <p>AWS Backup</p> </li> <li> <p>AWS Certificate Manager</p> </li> <li> <p>AWS Certificate Manager Private CA</p> </li> <li> <p>Amazon Cloud Directory</p> </li> <li> <p>AWS CloudFormation</p> </li> <li> <p>Amazon CloudFront</p> </li> <li> <p>AWS CloudHSM</p> </li> <li> <p>AWS CloudTrail</p> </li> <li> <p>Amazon CloudWatch (alarms only)</p> </li> <li> <p>Amazon CloudWatch Events</p> </li> <li> <p>Amazon CloudWatch Logs</p> </li> <li> <p>AWS CodeBuild</p> </li> <li> <p>AWS CodeCommit</p> </li> <li> <p>AWS CodePipeline</p> </li> <li> <p>AWS CodeStar</p> </li> <li> <p>Amazon Cognito Identity</p> </li> <li> <p>Amazon Cognito User Pools</p> </li> <li> <p>Amazon Comprehend</p> </li> <li> <p>AWS Config</p> </li> <li> <p>AWS Data Pipeline</p> </li> <li> <p>AWS Database Migration Service</p> </li> <li> <p>AWS DataSync</p> </li> <li> <p>AWS Direct Connect</p> </li> <li> <p>AWS Directory Service</p> </li> <li> <p>Amazon DynamoDB</p> </li> <li> <p>Amazon EBS</p> </li> <li> <p>Amazon EC2</p> </li> <li> <p>Amazon ECR</p> </li> <li> <p>Amazon ECS</p> </li> <li> <p>AWS Elastic Beanstalk</p> </li> <li> <p>Amazon Elastic File System</p> </li> <li> <p>Elastic Load Balancing</p> </li> <li> <p>Amazon ElastiCache</p> </li> <li> <p>Amazon Elasticsearch Service</p> </li> <li> <p>AWS Elemental MediaLive</p> </li> <li> <p>AWS Elemental MediaPackage</p> </li> <li> <p>AWS Elemental MediaTailor</p> </li> <li> <p>Amazon EMR</p> </li> <li> <p>Amazon FSx</p> </li> <li> <p>Amazon S3 Glacier</p> </li> <li> <p>AWS Glue</p> </li> <li> <p>Amazon GuardDuty</p> </li> <li> <p>Amazon Inspector</p> </li> <li> <p>AWS IoT Analytics</p> </li> <li> <p>AWS IoT Core</p> </li> <li> <p>AWS IoT Device Defender</p> </li> <li> <p>AWS IoT Device Management</p> </li> <li> <p>AWS IoT Events</p> </li> <li> <p>AWS IoT Greengrass</p> </li> <li> <p>AWS Key Management Service</p> </li> <li> <p>Amazon Kinesis</p> </li> <li> <p>Amazon Kinesis Data Analytics</p> </li> <li> <p>Amazon Kinesis Data Firehose</p> </li> <li> <p>AWS Lambda</p> </li> <li> <p>AWS License Manager</p> </li> <li> <p>Amazon Machine Learning</p> </li> <li> <p>Amazon MQ</p> </li> <li> <p>Amazon MSK</p> </li> <li> <p>Amazon Neptune</p> </li> <li> <p>AWS OpsWorks</p> </li> <li> <p>AWS Organizations</p> </li> <li> <p>Amazon Quantum Ledger Database (QLDB)</p> </li> <li> <p>Amazon RDS</p> </li> <li> <p>Amazon Redshift</p> </li> <li> <p>AWS Resource Access Manager</p> </li> <li> <p>AWS Resource Groups</p> </li> <li> <p>AWS RoboMaker</p> </li> <li> <p>Amazon Route 53</p> </li> <li> <p>Amazon Route 53 Resolver</p> </li> <li> <p>Amazon S3 (buckets only)</p> </li> <li> <p>Amazon SageMaker</p> </li> <li> <p>AWS Secrets Manager</p> </li> <li> <p>AWS Security Hub</p> </li> <li> <p>AWS Service Catalog</p> </li> <li> <p>Amazon Simple Notification Service (SNS)</p> </li> <li> <p>Amazon Simple Queue Service (SQS)</p> </li> <li> <p>AWS Step Functions</p> </li> <li> <p>AWS Storage Gateway</p> </li> <li> <p>AWS Systems Manager</p> </li> <li> <p>AWS Transfer for SFTP</p> </li> <li> <p>Amazon VPC</p> </li> <li> <p>Amazon WorkSpaces</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/tagging/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "tagging.ap-northeast-1.amazonaws.com", "ap-southeast-1": "tagging.ap-southeast-1.amazonaws.com",
                           "us-west-2": "tagging.us-west-2.amazonaws.com",
                           "eu-west-2": "tagging.eu-west-2.amazonaws.com", "ap-northeast-3": "tagging.ap-northeast-3.amazonaws.com", "eu-central-1": "tagging.eu-central-1.amazonaws.com",
                           "us-east-2": "tagging.us-east-2.amazonaws.com",
                           "us-east-1": "tagging.us-east-1.amazonaws.com", "cn-northwest-1": "tagging.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "tagging.ap-south-1.amazonaws.com",
                           "eu-north-1": "tagging.eu-north-1.amazonaws.com", "ap-northeast-2": "tagging.ap-northeast-2.amazonaws.com",
                           "us-west-1": "tagging.us-west-1.amazonaws.com", "us-gov-east-1": "tagging.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "tagging.eu-west-3.amazonaws.com",
                           "cn-north-1": "tagging.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "tagging.sa-east-1.amazonaws.com",
                           "eu-west-1": "tagging.eu-west-1.amazonaws.com", "us-gov-west-1": "tagging.us-gov-west-1.amazonaws.com", "ap-southeast-2": "tagging.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "tagging.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "tagging.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "tagging.ap-southeast-1.amazonaws.com",
      "us-west-2": "tagging.us-west-2.amazonaws.com",
      "eu-west-2": "tagging.eu-west-2.amazonaws.com",
      "ap-northeast-3": "tagging.ap-northeast-3.amazonaws.com",
      "eu-central-1": "tagging.eu-central-1.amazonaws.com",
      "us-east-2": "tagging.us-east-2.amazonaws.com",
      "us-east-1": "tagging.us-east-1.amazonaws.com",
      "cn-northwest-1": "tagging.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "tagging.ap-south-1.amazonaws.com",
      "eu-north-1": "tagging.eu-north-1.amazonaws.com",
      "ap-northeast-2": "tagging.ap-northeast-2.amazonaws.com",
      "us-west-1": "tagging.us-west-1.amazonaws.com",
      "us-gov-east-1": "tagging.us-gov-east-1.amazonaws.com",
      "eu-west-3": "tagging.eu-west-3.amazonaws.com",
      "cn-north-1": "tagging.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "tagging.sa-east-1.amazonaws.com",
      "eu-west-1": "tagging.eu-west-1.amazonaws.com",
      "us-gov-west-1": "tagging.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "tagging.ap-southeast-2.amazonaws.com",
      "ca-central-1": "tagging.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "resourcegroupstaggingapi"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeReportCreation_605927 = ref object of OpenApiRestCall_605589
proc url_DescribeReportCreation_605929(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeReportCreation_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the status of the <code>StartReportCreation</code> operation. </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
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
      "ResourceGroupsTaggingAPI_20170126.DescribeReportCreation"))
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

proc call*(call_606085: Call_DescribeReportCreation_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the status of the <code>StartReportCreation</code> operation. </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_DescribeReportCreation_605927; body: JsonNode): Recallable =
  ## describeReportCreation
  ## <p>Describes the status of the <code>StartReportCreation</code> operation. </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var describeReportCreation* = Call_DescribeReportCreation_605927(
    name: "describeReportCreation", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.DescribeReportCreation",
    validator: validate_DescribeReportCreation_605928, base: "/",
    url: url_DescribeReportCreation_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummary_606196 = ref object of OpenApiRestCall_605589
proc url_GetComplianceSummary_606198(protocol: Scheme; host: string; base: string;
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

proc validate_GetComplianceSummary_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a table that shows counts of resources that are noncompliant with their tag policies.</p> <p>For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_606199 = query.getOrDefault("MaxResults")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "MaxResults", valid_606199
  var valid_606200 = query.getOrDefault("PaginationToken")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "PaginationToken", valid_606200
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
  var valid_606201 = header.getOrDefault("X-Amz-Target")
  valid_606201 = validateParameter(valid_606201, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetComplianceSummary"))
  if valid_606201 != nil:
    section.add "X-Amz-Target", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Signature")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Signature", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Content-Sha256", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Date")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Date", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Credential")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Credential", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Security-Token")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Security-Token", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Algorithm")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Algorithm", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-SignedHeaders", valid_606208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606210: Call_GetComplianceSummary_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a table that shows counts of resources that are noncompliant with their tag policies.</p> <p>For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_606210.validator(path, query, header, formData, body)
  let scheme = call_606210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606210.url(scheme.get, call_606210.host, call_606210.base,
                         call_606210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606210, url, valid)

proc call*(call_606211: Call_GetComplianceSummary_606196; body: JsonNode;
          MaxResults: string = ""; PaginationToken: string = ""): Recallable =
  ## getComplianceSummary
  ## <p>Returns a table that shows counts of resources that are noncompliant with their tag policies.</p> <p>For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_606212 = newJObject()
  var body_606213 = newJObject()
  add(query_606212, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_606213 = body
  add(query_606212, "PaginationToken", newJString(PaginationToken))
  result = call_606211.call(nil, query_606212, nil, nil, body_606213)

var getComplianceSummary* = Call_GetComplianceSummary_606196(
    name: "getComplianceSummary", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetComplianceSummary",
    validator: validate_GetComplianceSummary_606197, base: "/",
    url: url_GetComplianceSummary_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_606215 = ref object of OpenApiRestCall_605589
proc url_GetResources_606217(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_606216(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified Region for the AWS account.</p> <p>Depending on what information you want returned, you can also specify the following:</p> <ul> <li> <p> <i>Filters</i> that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources.</p> </li> <li> <p>Information about compliance with the account's effective tag policy. For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query is complete. Queries occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourcesPerPage: JString
  ##                   : Pagination limit
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_606218 = query.getOrDefault("ResourcesPerPage")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "ResourcesPerPage", valid_606218
  var valid_606219 = query.getOrDefault("PaginationToken")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "PaginationToken", valid_606219
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
  var valid_606220 = header.getOrDefault("X-Amz-Target")
  valid_606220 = validateParameter(valid_606220, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_606220 != nil:
    section.add "X-Amz-Target", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Signature")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Signature", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Content-Sha256", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Date")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Date", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Credential")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Credential", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Security-Token")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Security-Token", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Algorithm")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Algorithm", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-SignedHeaders", valid_606227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606229: Call_GetResources_606215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified Region for the AWS account.</p> <p>Depending on what information you want returned, you can also specify the following:</p> <ul> <li> <p> <i>Filters</i> that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources.</p> </li> <li> <p>Information about compliance with the account's effective tag policy. For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query is complete. Queries occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_606229.validator(path, query, header, formData, body)
  let scheme = call_606229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606229.url(scheme.get, call_606229.host, call_606229.base,
                         call_606229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606229, url, valid)

proc call*(call_606230: Call_GetResources_606215; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified Region for the AWS account.</p> <p>Depending on what information you want returned, you can also specify the following:</p> <ul> <li> <p> <i>Filters</i> that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources.</p> </li> <li> <p>Information about compliance with the account's effective tag policy. For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query is complete. Queries occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_606231 = newJObject()
  var body_606232 = newJObject()
  add(query_606231, "ResourcesPerPage", newJString(ResourcesPerPage))
  if body != nil:
    body_606232 = body
  add(query_606231, "PaginationToken", newJString(PaginationToken))
  result = call_606230.call(nil, query_606231, nil, nil, body_606232)

var getResources* = Call_GetResources_606215(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_606216, base: "/", url: url_GetResources_606217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_606233 = ref object of OpenApiRestCall_605589
proc url_GetTagKeys_606235(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTagKeys_606234(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag keys in the specified Region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_606236 = query.getOrDefault("PaginationToken")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "PaginationToken", valid_606236
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
  var valid_606237 = header.getOrDefault("X-Amz-Target")
  valid_606237 = validateParameter(valid_606237, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_606237 != nil:
    section.add "X-Amz-Target", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_GetTagKeys_606233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified Region for the AWS account.
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_GetTagKeys_606233; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified Region for the AWS account.
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_606248 = newJObject()
  var body_606249 = newJObject()
  if body != nil:
    body_606249 = body
  add(query_606248, "PaginationToken", newJString(PaginationToken))
  result = call_606247.call(nil, query_606248, nil, nil, body_606249)

var getTagKeys* = Call_GetTagKeys_606233(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_606234,
                                      base: "/", url: url_GetTagKeys_606235,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_606250 = ref object of OpenApiRestCall_605589
proc url_GetTagValues_606252(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagValues_606251(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag values for the specified key in the specified Region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_606253 = query.getOrDefault("PaginationToken")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "PaginationToken", valid_606253
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
  var valid_606254 = header.getOrDefault("X-Amz-Target")
  valid_606254 = validateParameter(valid_606254, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_606254 != nil:
    section.add "X-Amz-Target", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Signature")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Signature", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Content-Sha256", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Date")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Date", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Credential")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Credential", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Security-Token")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Security-Token", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Algorithm")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Algorithm", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-SignedHeaders", valid_606261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606263: Call_GetTagValues_606250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified Region for the AWS account.
  ## 
  let valid = call_606263.validator(path, query, header, formData, body)
  let scheme = call_606263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606263.url(scheme.get, call_606263.host, call_606263.base,
                         call_606263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606263, url, valid)

proc call*(call_606264: Call_GetTagValues_606250; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified Region for the AWS account.
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_606265 = newJObject()
  var body_606266 = newJObject()
  if body != nil:
    body_606266 = body
  add(query_606265, "PaginationToken", newJString(PaginationToken))
  result = call_606264.call(nil, query_606265, nil, nil, body_606266)

var getTagValues* = Call_GetTagValues_606250(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_606251, base: "/", url: url_GetTagValues_606252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReportCreation_606267 = ref object of OpenApiRestCall_605589
proc url_StartReportCreation_606269(protocol: Scheme; host: string; base: string;
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

proc validate_StartReportCreation_606268(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Generates a report that lists all tagged resources in accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. </p> <p>The generated report is saved to the following location:</p> <p> <code>s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv</code> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
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
  var valid_606270 = header.getOrDefault("X-Amz-Target")
  valid_606270 = validateParameter(valid_606270, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.StartReportCreation"))
  if valid_606270 != nil:
    section.add "X-Amz-Target", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Signature")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Signature", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Content-Sha256", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Date")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Date", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Credential")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Credential", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Security-Token")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Security-Token", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Algorithm")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Algorithm", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-SignedHeaders", valid_606277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606279: Call_StartReportCreation_606267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a report that lists all tagged resources in accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. </p> <p>The generated report is saved to the following location:</p> <p> <code>s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv</code> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_606279.validator(path, query, header, formData, body)
  let scheme = call_606279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606279.url(scheme.get, call_606279.host, call_606279.base,
                         call_606279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606279, url, valid)

proc call*(call_606280: Call_StartReportCreation_606267; body: JsonNode): Recallable =
  ## startReportCreation
  ## <p>Generates a report that lists all tagged resources in accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. </p> <p>The generated report is saved to the following location:</p> <p> <code>s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv</code> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   body: JObject (required)
  var body_606281 = newJObject()
  if body != nil:
    body_606281 = body
  result = call_606280.call(nil, nil, nil, nil, body_606281)

var startReportCreation* = Call_StartReportCreation_606267(
    name: "startReportCreation", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.StartReportCreation",
    validator: validate_StartReportCreation_606268, base: "/",
    url: url_StartReportCreation_606269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_606282 = ref object of OpenApiRestCall_605589
proc url_TagResources_606284(protocol: Scheme; host: string; base: string;
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

proc validate_TagResources_606283(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of services that support tagging, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions">Tag Naming and Usage Conventions</a> in the <i>AWS General Reference.</i> </p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> </ul>
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
  var valid_606285 = header.getOrDefault("X-Amz-Target")
  valid_606285 = validateParameter(valid_606285, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_606285 != nil:
    section.add "X-Amz-Target", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Signature")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Signature", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Content-Sha256", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Date")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Date", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Credential")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Credential", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Security-Token")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Security-Token", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Algorithm")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Algorithm", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-SignedHeaders", valid_606292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606294: Call_TagResources_606282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of services that support tagging, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions">Tag Naming and Usage Conventions</a> in the <i>AWS General Reference.</i> </p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> </ul>
  ## 
  let valid = call_606294.validator(path, query, header, formData, body)
  let scheme = call_606294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606294.url(scheme.get, call_606294.host, call_606294.base,
                         call_606294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606294, url, valid)

proc call*(call_606295: Call_TagResources_606282; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of services that support tagging, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions">Tag Naming and Usage Conventions</a> in the <i>AWS General Reference.</i> </p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606296 = newJObject()
  if body != nil:
    body_606296 = body
  result = call_606295.call(nil, nil, nil, nil, body_606296)

var tagResources* = Call_TagResources_606282(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_606283, base: "/", url: url_TagResources_606284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_606297 = ref object of OpenApiRestCall_605589
proc url_UntagResources_606299(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResources_606298(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> </ul>
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
  var valid_606300 = header.getOrDefault("X-Amz-Target")
  valid_606300 = validateParameter(valid_606300, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_606300 != nil:
    section.add "X-Amz-Target", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606309: Call_UntagResources_606297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_606309.validator(path, query, header, formData, body)
  let scheme = call_606309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606309.url(scheme.get, call_606309.host, call_606309.base,
                         call_606309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606309, url, valid)

proc call*(call_606310: Call_UntagResources_606297; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606311 = newJObject()
  if body != nil:
    body_606311 = body
  result = call_606310.call(nil, nil, nil, nil, body_606311)

var untagResources* = Call_UntagResources_606297(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_606298, base: "/", url: url_UntagResources_606299,
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
