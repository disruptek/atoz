
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Groups Tagging API
## version: 2017-01-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Resource Groups Tagging API</fullname> <p>This guide describes the API operations for the resource groups tagging.</p> <p>A tag is a label that you assign to an AWS resource. A tag consists of a key and a value, both of which you define. For example, if you have two Amazon EC2 instances, you might assign both a tag key of "Stack." But the value of "Stack" might be "Testing" for one and "Production" for the other.</p> <p>Tagging can help you organize your resources and enables you to simplify resource management, access management and cost allocation. </p> <p>You can use the resource groups tagging API operations to complete the following tasks:</p> <ul> <li> <p>Tag and untag supported resources located in the specified region for the AWS account</p> </li> <li> <p>Use tag-based filters to search for resources located in the specified region for the AWS account</p> </li> <li> <p>List all existing tag keys in the specified region for the AWS account</p> </li> <li> <p>List all existing values for the specified key in the specified region for the AWS account</p> </li> </ul> <p/> <p>To use resource groups tagging API operations, you must add the following permissions to your IAM policy:</p> <ul> <li> <p> <code>tag:GetResources</code> </p> </li> <li> <p> <code>tag:TagResources</code> </p> </li> <li> <p> <code>tag:UntagResources</code> </p> </li> <li> <p> <code>tag:GetTagKeys</code> </p> </li> <li> <p> <code>tag:GetTagValues</code> </p> </li> </ul> <p>You'll also need permissions to access the resources of individual services so that you can tag and untag those resources.</p> <p>For more information on IAM policies, see <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage.html">Managing IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p>You can use the Resource Groups Tagging API to tag resources for the following AWS services.</p> <ul> <li> <p>Alexa for Business (a4b)</p> </li> <li> <p>API Gateway</p> </li> <li> <p>AWS AppStream</p> </li> <li> <p>AWS AppSync</p> </li> <li> <p>AWS App Mesh</p> </li> <li> <p>Amazon Athena</p> </li> <li> <p>Amazon Aurora</p> </li> <li> <p>AWS Backup</p> </li> <li> <p>AWS Certificate Manager</p> </li> <li> <p>AWS Certificate Manager Private CA</p> </li> <li> <p>Amazon Cloud Directory</p> </li> <li> <p>AWS CloudFormation</p> </li> <li> <p>Amazon CloudFront</p> </li> <li> <p>AWS CloudHSM</p> </li> <li> <p>AWS CloudTrail</p> </li> <li> <p>Amazon CloudWatch (alarms only)</p> </li> <li> <p>Amazon CloudWatch Events</p> </li> <li> <p>Amazon CloudWatch Logs</p> </li> <li> <p>AWS CodeBuild</p> </li> <li> <p>AWS CodeCommit</p> </li> <li> <p>AWS CodePipeline</p> </li> <li> <p>AWS CodeStar</p> </li> <li> <p>Amazon Cognito Identity</p> </li> <li> <p>Amazon Cognito User Pools</p> </li> <li> <p>Amazon Comprehend</p> </li> <li> <p>AWS Config</p> </li> <li> <p>AWS Data Pipeline</p> </li> <li> <p>AWS Database Migration Service</p> </li> <li> <p>AWS Datasync</p> </li> <li> <p>AWS Direct Connect</p> </li> <li> <p>AWS Directory Service</p> </li> <li> <p>Amazon DynamoDB</p> </li> <li> <p>Amazon EBS</p> </li> <li> <p>Amazon EC2</p> </li> <li> <p>Amazon ECR</p> </li> <li> <p>Amazon ECS</p> </li> <li> <p>AWS Elastic Beanstalk</p> </li> <li> <p>Amazon Elastic File System</p> </li> <li> <p>Elastic Load Balancing</p> </li> <li> <p>Amazon ElastiCache</p> </li> <li> <p>Amazon Elasticsearch Service</p> </li> <li> <p>AWS Elemental MediaLive</p> </li> <li> <p>AWS Elemental MediaPackage</p> </li> <li> <p>AWS Elemental MediaTailor</p> </li> <li> <p>Amazon EMR</p> </li> <li> <p>Amazon FSx</p> </li> <li> <p>Amazon Glacier</p> </li> <li> <p>AWS Glue</p> </li> <li> <p>Amazon Inspector</p> </li> <li> <p>AWS IoT Analytics</p> </li> <li> <p>AWS IoT Core</p> </li> <li> <p>AWS IoT Device Defender</p> </li> <li> <p>AWS IoT Device Management</p> </li> <li> <p>AWS IoT Greengrass</p> </li> <li> <p>AWS Key Management Service</p> </li> <li> <p>Amazon Kinesis</p> </li> <li> <p>Amazon Kinesis Data Analytics</p> </li> <li> <p>Amazon Kinesis Data Firehose</p> </li> <li> <p>AWS Lambda</p> </li> <li> <p>AWS License Manager</p> </li> <li> <p>Amazon Machine Learning</p> </li> <li> <p>Amazon MQ</p> </li> <li> <p>Amazon MSK</p> </li> <li> <p>Amazon Neptune</p> </li> <li> <p>AWS OpsWorks</p> </li> <li> <p>Amazon RDS</p> </li> <li> <p>Amazon Redshift</p> </li> <li> <p>AWS Resource Access Manager</p> </li> <li> <p>AWS Resource Groups</p> </li> <li> <p>AWS RoboMaker</p> </li> <li> <p>Amazon Route 53</p> </li> <li> <p>Amazon Route 53 Resolver</p> </li> <li> <p>Amazon S3 (buckets only)</p> </li> <li> <p>Amazon SageMaker</p> </li> <li> <p>AWS Secrets Manager</p> </li> <li> <p>AWS Service Catalog</p> </li> <li> <p>Amazon Simple Notification Service (SNS)</p> </li> <li> <p>Amazon Simple Queue Service (SQS)</p> </li> <li> <p>AWS Simple System Manager (SSM)</p> </li> <li> <p>AWS Step Functions</p> </li> <li> <p>AWS Storage Gateway</p> </li> <li> <p>AWS Transfer for SFTP</p> </li> <li> <p>Amazon VPC</p> </li> <li> <p>Amazon WorkSpaces</p> </li> </ul>
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

  OpenApiRestCall_600424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600424): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetResources_600761 = ref object of OpenApiRestCall_600424
proc url_GetResources_600763(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResources_600762(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
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
  var valid_600875 = query.getOrDefault("ResourcesPerPage")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "ResourcesPerPage", valid_600875
  var valid_600876 = query.getOrDefault("PaginationToken")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "PaginationToken", valid_600876
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
  var valid_600877 = header.getOrDefault("X-Amz-Date")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Date", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Security-Token")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Security-Token", valid_600878
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600892 = header.getOrDefault("X-Amz-Target")
  valid_600892 = validateParameter(valid_600892, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_600892 != nil:
    section.add "X-Amz-Target", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Content-Sha256", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Algorithm")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Algorithm", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Signature")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Signature", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-SignedHeaders", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Credential")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Credential", valid_600897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600921: Call_GetResources_600761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_600921.validator(path, query, header, formData, body)
  let scheme = call_600921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600921.url(scheme.get, call_600921.host, call_600921.base,
                         call_600921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600921, url, valid)

proc call*(call_600992: Call_GetResources_600761; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_600993 = newJObject()
  var body_600995 = newJObject()
  add(query_600993, "ResourcesPerPage", newJString(ResourcesPerPage))
  add(query_600993, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_600995 = body
  result = call_600992.call(nil, query_600993, nil, nil, body_600995)

var getResources* = Call_GetResources_600761(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_600762, base: "/", url: url_GetResources_600763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_601034 = ref object of OpenApiRestCall_600424
proc url_GetTagKeys_601036(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagKeys_601035(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_601037 = query.getOrDefault("PaginationToken")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "PaginationToken", valid_601037
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
  var valid_601038 = header.getOrDefault("X-Amz-Date")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Date", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Security-Token")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Security-Token", valid_601039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601040 = header.getOrDefault("X-Amz-Target")
  valid_601040 = validateParameter(valid_601040, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_601040 != nil:
    section.add "X-Amz-Target", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Content-Sha256", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Algorithm")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Algorithm", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Signature")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Signature", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-SignedHeaders", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Credential")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Credential", valid_601045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601047: Call_GetTagKeys_601034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  let valid = call_601047.validator(path, query, header, formData, body)
  let scheme = call_601047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601047.url(scheme.get, call_601047.host, call_601047.base,
                         call_601047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601047, url, valid)

proc call*(call_601048: Call_GetTagKeys_601034; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_601049 = newJObject()
  var body_601050 = newJObject()
  add(query_601049, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_601050 = body
  result = call_601048.call(nil, query_601049, nil, nil, body_601050)

var getTagKeys* = Call_GetTagKeys_601034(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_601035,
                                      base: "/", url: url_GetTagKeys_601036,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_601051 = ref object of OpenApiRestCall_600424
proc url_GetTagValues_601053(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagValues_601052(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_601054 = query.getOrDefault("PaginationToken")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "PaginationToken", valid_601054
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_GetTagValues_601051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_GetTagValues_601051; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_601066 = newJObject()
  var body_601067 = newJObject()
  add(query_601066, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_601067 = body
  result = call_601065.call(nil, query_601066, nil, nil, body_601067)

var getTagValues* = Call_GetTagValues_601051(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_601052, base: "/", url: url_GetTagValues_601053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_601068 = ref object of OpenApiRestCall_600424
proc url_TagResources_601070(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResources_601069(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
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
  var valid_601071 = header.getOrDefault("X-Amz-Date")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Date", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Security-Token")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Security-Token", valid_601072
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601073 = header.getOrDefault("X-Amz-Target")
  valid_601073 = validateParameter(valid_601073, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_601073 != nil:
    section.add "X-Amz-Target", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Content-Sha256", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Algorithm")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Algorithm", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Signature")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Signature", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-SignedHeaders", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Credential")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Credential", valid_601078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_TagResources_601068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_TagResources_601068; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601082 = newJObject()
  if body != nil:
    body_601082 = body
  result = call_601081.call(nil, nil, nil, nil, body_601082)

var tagResources* = Call_TagResources_601068(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_601069, base: "/", url: url_TagResources_601070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_601083 = ref object of OpenApiRestCall_600424
proc url_UntagResources_601085(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResources_601084(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
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
  var valid_601086 = header.getOrDefault("X-Amz-Date")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Date", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Security-Token")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Security-Token", valid_601087
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601088 = header.getOrDefault("X-Amz-Target")
  valid_601088 = validateParameter(valid_601088, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_601088 != nil:
    section.add "X-Amz-Target", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601095: Call_UntagResources_601083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_601095.validator(path, query, header, formData, body)
  let scheme = call_601095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601095.url(scheme.get, call_601095.host, call_601095.base,
                         call_601095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601095, url, valid)

proc call*(call_601096: Call_UntagResources_601083; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601097 = newJObject()
  if body != nil:
    body_601097 = body
  result = call_601096.call(nil, nil, nil, nil, body_601097)

var untagResources* = Call_UntagResources_601083(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_601084, base: "/", url: url_UntagResources_601085,
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
