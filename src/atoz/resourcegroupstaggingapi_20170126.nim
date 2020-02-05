
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
## <fullname>Resource Groups Tagging API</fullname> <p>This guide describes the API operations for the resource groups tagging.</p> <p>A tag is a label that you assign to an AWS resource. A tag consists of a key and a value, both of which you define. For example, if you have two Amazon EC2 instances, you might assign both a tag key of "Stack." But the value of "Stack" might be "Testing" for one and "Production" for the other.</p> <p>Tagging can help you organize your resources and enables you to simplify resource management, access management and cost allocation. </p> <p>You can use the resource groups tagging API operations to complete the following tasks:</p> <ul> <li> <p>Tag and untag supported resources located in the specified Region for the AWS account.</p> </li> <li> <p>Use tag-based filters to search for resources located in the specified Region for the AWS account.</p> </li> <li> <p>List all existing tag keys in the specified Region for the AWS account.</p> </li> <li> <p>List all existing values for the specified key in the specified Region for the AWS account.</p> </li> </ul> <p>To use resource groups tagging API operations, you must add the following permissions to your IAM policy:</p> <ul> <li> <p> <code>tag:GetResources</code> </p> </li> <li> <p> <code>tag:TagResources</code> </p> </li> <li> <p> <code>tag:UntagResources</code> </p> </li> <li> <p> <code>tag:GetTagKeys</code> </p> </li> <li> <p> <code>tag:GetTagValues</code> </p> </li> </ul> <p>You'll also need permissions to access the resources of individual services so that you can tag and untag those resources.</p> <p>For more information on IAM policies, see <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage.html">Managing IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p>You can use the Resource Groups Tagging API to tag resources for the following AWS services.</p> <ul> <li> <p>Alexa for Business (a4b)</p> </li> <li> <p>API Gateway</p> </li> <li> <p>Amazon AppStream</p> </li> <li> <p>AWS AppSync</p> </li> <li> <p>AWS App Mesh</p> </li> <li> <p>Amazon Athena</p> </li> <li> <p>Amazon Aurora</p> </li> <li> <p>AWS Backup</p> </li> <li> <p>AWS Certificate Manager</p> </li> <li> <p>AWS Certificate Manager Private CA</p> </li> <li> <p>Amazon Cloud Directory</p> </li> <li> <p>AWS CloudFormation</p> </li> <li> <p>Amazon CloudFront</p> </li> <li> <p>AWS CloudHSM</p> </li> <li> <p>AWS CloudTrail</p> </li> <li> <p>Amazon CloudWatch (alarms only)</p> </li> <li> <p>Amazon CloudWatch Events</p> </li> <li> <p>Amazon CloudWatch Logs</p> </li> <li> <p>AWS CodeBuild</p> </li> <li> <p>AWS CodeCommit</p> </li> <li> <p>AWS CodePipeline</p> </li> <li> <p>AWS CodeStar</p> </li> <li> <p>Amazon Cognito Identity</p> </li> <li> <p>Amazon Cognito User Pools</p> </li> <li> <p>Amazon Comprehend</p> </li> <li> <p>AWS Config</p> </li> <li> <p>AWS Data Exchange</p> </li> <li> <p>AWS Data Pipeline</p> </li> <li> <p>AWS Database Migration Service</p> </li> <li> <p>AWS DataSync</p> </li> <li> <p>AWS Device Farm</p> </li> <li> <p>AWS Direct Connect</p> </li> <li> <p>AWS Directory Service</p> </li> <li> <p>Amazon DynamoDB</p> </li> <li> <p>Amazon EBS</p> </li> <li> <p>Amazon EC2</p> </li> <li> <p>Amazon ECR</p> </li> <li> <p>Amazon ECS</p> </li> <li> <p>Amazon EKS</p> </li> <li> <p>AWS Elastic Beanstalk</p> </li> <li> <p>Amazon Elastic File System</p> </li> <li> <p>Elastic Load Balancing</p> </li> <li> <p>Amazon ElastiCache</p> </li> <li> <p>Amazon Elasticsearch Service</p> </li> <li> <p>AWS Elemental MediaLive</p> </li> <li> <p>AWS Elemental MediaPackage</p> </li> <li> <p>AWS Elemental MediaTailor</p> </li> <li> <p>Amazon EMR</p> </li> <li> <p>Amazon FSx</p> </li> <li> <p>Amazon S3 Glacier</p> </li> <li> <p>AWS Glue</p> </li> <li> <p>Amazon GuardDuty</p> </li> <li> <p>Amazon Inspector</p> </li> <li> <p>AWS IoT Analytics</p> </li> <li> <p>AWS IoT Core</p> </li> <li> <p>AWS IoT Device Defender</p> </li> <li> <p>AWS IoT Device Management</p> </li> <li> <p>AWS IoT Events</p> </li> <li> <p>AWS IoT Greengrass</p> </li> <li> <p>AWS IoT 1-Click</p> </li> <li> <p>AWS Key Management Service</p> </li> <li> <p>Amazon Kinesis</p> </li> <li> <p>Amazon Kinesis Data Analytics</p> </li> <li> <p>Amazon Kinesis Data Firehose</p> </li> <li> <p>AWS Lambda</p> </li> <li> <p>AWS License Manager</p> </li> <li> <p>Amazon Machine Learning</p> </li> <li> <p>Amazon MQ</p> </li> <li> <p>Amazon MSK</p> </li> <li> <p>Amazon Neptune</p> </li> <li> <p>AWS OpsWorks</p> </li> <li> <p>AWS Organizations</p> </li> <li> <p>Amazon Quantum Ledger Database (QLDB)</p> </li> <li> <p>Amazon RDS</p> </li> <li> <p>Amazon Redshift</p> </li> <li> <p>AWS Resource Access Manager</p> </li> <li> <p>AWS Resource Groups</p> </li> <li> <p>AWS RoboMaker</p> </li> <li> <p>Amazon Route 53</p> </li> <li> <p>Amazon Route 53 Resolver</p> </li> <li> <p>Amazon S3 (buckets only)</p> </li> <li> <p>Amazon SageMaker</p> </li> <li> <p>AWS Secrets Manager</p> </li> <li> <p>AWS Security Hub</p> </li> <li> <p>AWS Service Catalog</p> </li> <li> <p>Amazon Simple Notification Service (SNS)</p> </li> <li> <p>Amazon Simple Queue Service (SQS)</p> </li> <li> <p>Amazon Simple Workflow Service</p> </li> <li> <p>AWS Step Functions</p> </li> <li> <p>AWS Storage Gateway</p> </li> <li> <p>AWS Systems Manager</p> </li> <li> <p>AWS Transfer for SFTP</p> </li> <li> <p>Amazon VPC</p> </li> <li> <p>Amazon WorkSpaces</p> </li> </ul>
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_DescribeReportCreation_612996 = ref object of OpenApiRestCall_612658
proc url_DescribeReportCreation_612998(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeReportCreation_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.DescribeReportCreation"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_DescribeReportCreation_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the status of the <code>StartReportCreation</code> operation. </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_DescribeReportCreation_612996; body: JsonNode): Recallable =
  ## describeReportCreation
  ## <p>Describes the status of the <code>StartReportCreation</code> operation. </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var describeReportCreation* = Call_DescribeReportCreation_612996(
    name: "describeReportCreation", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.DescribeReportCreation",
    validator: validate_DescribeReportCreation_612997, base: "/",
    url: url_DescribeReportCreation_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummary_613265 = ref object of OpenApiRestCall_612658
proc url_GetComplianceSummary_613267(protocol: Scheme; host: string; base: string;
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

proc validate_GetComplianceSummary_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = query.getOrDefault("MaxResults")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "MaxResults", valid_613268
  var valid_613269 = query.getOrDefault("PaginationToken")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "PaginationToken", valid_613269
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
  var valid_613270 = header.getOrDefault("X-Amz-Target")
  valid_613270 = validateParameter(valid_613270, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetComplianceSummary"))
  if valid_613270 != nil:
    section.add "X-Amz-Target", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Signature", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Content-Sha256", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Date")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Date", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Credential")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Credential", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Security-Token")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Security-Token", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Algorithm")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Algorithm", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-SignedHeaders", valid_613277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_GetComplianceSummary_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a table that shows counts of resources that are noncompliant with their tag policies.</p> <p>For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_GetComplianceSummary_613265; body: JsonNode;
          MaxResults: string = ""; PaginationToken: string = ""): Recallable =
  ## getComplianceSummary
  ## <p>Returns a table that shows counts of resources that are noncompliant with their tag policies.</p> <p>For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_613281 = newJObject()
  var body_613282 = newJObject()
  add(query_613281, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_613282 = body
  add(query_613281, "PaginationToken", newJString(PaginationToken))
  result = call_613280.call(nil, query_613281, nil, nil, body_613282)

var getComplianceSummary* = Call_GetComplianceSummary_613265(
    name: "getComplianceSummary", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetComplianceSummary",
    validator: validate_GetComplianceSummary_613266, base: "/",
    url: url_GetComplianceSummary_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_613284 = ref object of OpenApiRestCall_612658
proc url_GetResources_613286(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_613285(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613287 = query.getOrDefault("ResourcesPerPage")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "ResourcesPerPage", valid_613287
  var valid_613288 = query.getOrDefault("PaginationToken")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "PaginationToken", valid_613288
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
  var valid_613289 = header.getOrDefault("X-Amz-Target")
  valid_613289 = validateParameter(valid_613289, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_613289 != nil:
    section.add "X-Amz-Target", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Signature", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Content-Sha256", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Date")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Date", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Credential")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Credential", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Security-Token")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Security-Token", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Algorithm")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Algorithm", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-SignedHeaders", valid_613296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_GetResources_613284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified Region for the AWS account.</p> <p>Depending on what information you want returned, you can also specify the following:</p> <ul> <li> <p> <i>Filters</i> that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources.</p> </li> <li> <p>Information about compliance with the account's effective tag policy. For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query is complete. Queries occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_GetResources_613284; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified Region for the AWS account.</p> <p>Depending on what information you want returned, you can also specify the following:</p> <ul> <li> <p> <i>Filters</i> that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources.</p> </li> <li> <p>Information about compliance with the account's effective tag policy. For more information on tag policies, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html">Tag Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query is complete. Queries occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_613300 = newJObject()
  var body_613301 = newJObject()
  add(query_613300, "ResourcesPerPage", newJString(ResourcesPerPage))
  if body != nil:
    body_613301 = body
  add(query_613300, "PaginationToken", newJString(PaginationToken))
  result = call_613299.call(nil, query_613300, nil, nil, body_613301)

var getResources* = Call_GetResources_613284(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_613285, base: "/", url: url_GetResources_613286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_613302 = ref object of OpenApiRestCall_612658
proc url_GetTagKeys_613304(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTagKeys_613303(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613305 = query.getOrDefault("PaginationToken")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "PaginationToken", valid_613305
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
  var valid_613306 = header.getOrDefault("X-Amz-Target")
  valid_613306 = validateParameter(valid_613306, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_613306 != nil:
    section.add "X-Amz-Target", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_GetTagKeys_613302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified Region for the AWS account.
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_GetTagKeys_613302; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified Region for the AWS account.
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_613317 = newJObject()
  var body_613318 = newJObject()
  if body != nil:
    body_613318 = body
  add(query_613317, "PaginationToken", newJString(PaginationToken))
  result = call_613316.call(nil, query_613317, nil, nil, body_613318)

var getTagKeys* = Call_GetTagKeys_613302(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_613303,
                                      base: "/", url: url_GetTagKeys_613304,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_613319 = ref object of OpenApiRestCall_612658
proc url_GetTagValues_613321(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagValues_613320(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613322 = query.getOrDefault("PaginationToken")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "PaginationToken", valid_613322
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
  var valid_613323 = header.getOrDefault("X-Amz-Target")
  valid_613323 = validateParameter(valid_613323, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_613323 != nil:
    section.add "X-Amz-Target", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Signature")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Signature", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Content-Sha256", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Date")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Date", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Credential")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Credential", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Security-Token")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Security-Token", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Algorithm")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Algorithm", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-SignedHeaders", valid_613330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613332: Call_GetTagValues_613319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified Region for the AWS account.
  ## 
  let valid = call_613332.validator(path, query, header, formData, body)
  let scheme = call_613332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613332.url(scheme.get, call_613332.host, call_613332.base,
                         call_613332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613332, url, valid)

proc call*(call_613333: Call_GetTagValues_613319; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified Region for the AWS account.
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_613334 = newJObject()
  var body_613335 = newJObject()
  if body != nil:
    body_613335 = body
  add(query_613334, "PaginationToken", newJString(PaginationToken))
  result = call_613333.call(nil, query_613334, nil, nil, body_613335)

var getTagValues* = Call_GetTagValues_613319(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_613320, base: "/", url: url_GetTagValues_613321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReportCreation_613336 = ref object of OpenApiRestCall_612658
proc url_StartReportCreation_613338(protocol: Scheme; host: string; base: string;
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

proc validate_StartReportCreation_613337(path: JsonNode; query: JsonNode;
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
  var valid_613339 = header.getOrDefault("X-Amz-Target")
  valid_613339 = validateParameter(valid_613339, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.StartReportCreation"))
  if valid_613339 != nil:
    section.add "X-Amz-Target", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Signature")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Signature", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Content-Sha256", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Date")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Date", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Credential")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Credential", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Security-Token")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Security-Token", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Algorithm")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Algorithm", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-SignedHeaders", valid_613346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613348: Call_StartReportCreation_613336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a report that lists all tagged resources in accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. </p> <p>The generated report is saved to the following location:</p> <p> <code>s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv</code> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ## 
  let valid = call_613348.validator(path, query, header, formData, body)
  let scheme = call_613348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613348.url(scheme.get, call_613348.host, call_613348.base,
                         call_613348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613348, url, valid)

proc call*(call_613349: Call_StartReportCreation_613336; body: JsonNode): Recallable =
  ## startReportCreation
  ## <p>Generates a report that lists all tagged resources in accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. </p> <p>The generated report is saved to the following location:</p> <p> <code>s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv</code> </p> <p>You can call this operation only from the organization's master account and from the us-east-1 Region.</p>
  ##   body: JObject (required)
  var body_613350 = newJObject()
  if body != nil:
    body_613350 = body
  result = call_613349.call(nil, nil, nil, nil, body_613350)

var startReportCreation* = Call_StartReportCreation_613336(
    name: "startReportCreation", meth: HttpMethod.HttpPost,
    host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.StartReportCreation",
    validator: validate_StartReportCreation_613337, base: "/",
    url: url_StartReportCreation_613338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_613351 = ref object of OpenApiRestCall_612658
proc url_TagResources_613353(protocol: Scheme; host: string; base: string;
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

proc validate_TagResources_613352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613354 = header.getOrDefault("X-Amz-Target")
  valid_613354 = validateParameter(valid_613354, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_613354 != nil:
    section.add "X-Amz-Target", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Signature")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Signature", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Content-Sha256", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Date")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Date", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Credential")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Credential", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Security-Token")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Security-Token", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Algorithm")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Algorithm", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-SignedHeaders", valid_613361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613363: Call_TagResources_613351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of services that support tagging, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions">Tag Naming and Usage Conventions</a> in the <i>AWS General Reference.</i> </p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> </ul>
  ## 
  let valid = call_613363.validator(path, query, header, formData, body)
  let scheme = call_613363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613363.url(scheme.get, call_613363.host, call_613363.base,
                         call_613363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613363, url, valid)

proc call*(call_613364: Call_TagResources_613351; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of services that support tagging, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions">Tag Naming and Usage Conventions</a> in the <i>AWS General Reference.</i> </p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613365 = newJObject()
  if body != nil:
    body_613365 = body
  result = call_613364.call(nil, nil, nil, nil, body_613365)

var tagResources* = Call_TagResources_613351(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_613352, base: "/", url: url_TagResources_613353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_613366 = ref object of OpenApiRestCall_612658
proc url_UntagResources_613368(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResources_613367(path: JsonNode; query: JsonNode;
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
  var valid_613369 = header.getOrDefault("X-Amz-Target")
  valid_613369 = validateParameter(valid_613369, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_613369 != nil:
    section.add "X-Amz-Target", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Signature")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Signature", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Content-Sha256", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Date")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Date", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Credential")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Credential", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613378: Call_UntagResources_613366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_613378.validator(path, query, header, formData, body)
  let scheme = call_613378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613378.url(scheme.get, call_613378.host, call_613378.base,
                         call_613378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613378, url, valid)

proc call*(call_613379: Call_UntagResources_613366; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html">this list</a>.</p> </li> <li> <p>You can only tag resources that are located in the specified Region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613380 = newJObject()
  if body != nil:
    body_613380 = body
  result = call_613379.call(nil, nil, nil, nil, body_613380)

var untagResources* = Call_UntagResources_613366(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_613367, base: "/", url: url_UntagResources_613368,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
