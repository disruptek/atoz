
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
  Call_GetResources_602794 = ref object of OpenApiRestCall_602457
proc url_GetResources_602796(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResources_602795(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602908 = query.getOrDefault("ResourcesPerPage")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "ResourcesPerPage", valid_602908
  var valid_602909 = query.getOrDefault("PaginationToken")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "PaginationToken", valid_602909
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
  var valid_602910 = header.getOrDefault("X-Amz-Date")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Date", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Security-Token")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Security-Token", valid_602911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602925 = header.getOrDefault("X-Amz-Target")
  valid_602925 = validateParameter(valid_602925, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_602925 != nil:
    section.add "X-Amz-Target", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Content-Sha256", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Algorithm")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Algorithm", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Signature")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Signature", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-SignedHeaders", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Credential")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Credential", valid_602930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602954: Call_GetResources_602794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_602954.validator(path, query, header, formData, body)
  let scheme = call_602954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602954.url(scheme.get, call_602954.host, call_602954.base,
                         call_602954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602954, url, valid)

proc call*(call_603025: Call_GetResources_602794; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_603026 = newJObject()
  var body_603028 = newJObject()
  add(query_603026, "ResourcesPerPage", newJString(ResourcesPerPage))
  add(query_603026, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_603028 = body
  result = call_603025.call(nil, query_603026, nil, nil, body_603028)

var getResources* = Call_GetResources_602794(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_602795, base: "/", url: url_GetResources_602796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_603067 = ref object of OpenApiRestCall_602457
proc url_GetTagKeys_603069(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagKeys_603068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603070 = query.getOrDefault("PaginationToken")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "PaginationToken", valid_603070
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
  var valid_603071 = header.getOrDefault("X-Amz-Date")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Date", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Security-Token")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Security-Token", valid_603072
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603073 = header.getOrDefault("X-Amz-Target")
  valid_603073 = validateParameter(valid_603073, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_603073 != nil:
    section.add "X-Amz-Target", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Content-Sha256", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Algorithm")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Algorithm", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Signature")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Signature", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-SignedHeaders", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Credential")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Credential", valid_603078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603080: Call_GetTagKeys_603067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  let valid = call_603080.validator(path, query, header, formData, body)
  let scheme = call_603080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603080.url(scheme.get, call_603080.host, call_603080.base,
                         call_603080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603080, url, valid)

proc call*(call_603081: Call_GetTagKeys_603067; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_603082 = newJObject()
  var body_603083 = newJObject()
  add(query_603082, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_603083 = body
  result = call_603081.call(nil, query_603082, nil, nil, body_603083)

var getTagKeys* = Call_GetTagKeys_603067(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_603068,
                                      base: "/", url: url_GetTagKeys_603069,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_603084 = ref object of OpenApiRestCall_602457
proc url_GetTagValues_603086(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagValues_603085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603087 = query.getOrDefault("PaginationToken")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "PaginationToken", valid_603087
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
  var valid_603088 = header.getOrDefault("X-Amz-Date")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Date", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Security-Token")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Security-Token", valid_603089
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603090 = header.getOrDefault("X-Amz-Target")
  valid_603090 = validateParameter(valid_603090, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_603090 != nil:
    section.add "X-Amz-Target", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Content-Sha256", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Algorithm")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Algorithm", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Signature")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Signature", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-SignedHeaders", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Credential")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Credential", valid_603095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_GetTagValues_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_GetTagValues_603084; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_603099 = newJObject()
  var body_603100 = newJObject()
  add(query_603099, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_603100 = body
  result = call_603098.call(nil, query_603099, nil, nil, body_603100)

var getTagValues* = Call_GetTagValues_603084(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_603085, base: "/", url: url_GetTagValues_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_603101 = ref object of OpenApiRestCall_602457
proc url_TagResources_603103(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResources_603102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603106 = header.getOrDefault("X-Amz-Target")
  valid_603106 = validateParameter(valid_603106, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_603106 != nil:
    section.add "X-Amz-Target", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Content-Sha256", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Algorithm")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Algorithm", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Signature")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Signature", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-SignedHeaders", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Credential")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Credential", valid_603111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603113: Call_TagResources_603101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_603113.validator(path, query, header, formData, body)
  let scheme = call_603113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603113.url(scheme.get, call_603113.host, call_603113.base,
                         call_603113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603113, url, valid)

proc call*(call_603114: Call_TagResources_603101; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603115 = newJObject()
  if body != nil:
    body_603115 = body
  result = call_603114.call(nil, nil, nil, nil, body_603115)

var tagResources* = Call_TagResources_603101(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_603102, base: "/", url: url_TagResources_603103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_603116 = ref object of OpenApiRestCall_602457
proc url_UntagResources_603118(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResources_603117(path: JsonNode; query: JsonNode;
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
  var valid_603119 = header.getOrDefault("X-Amz-Date")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Date", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603121 = header.getOrDefault("X-Amz-Target")
  valid_603121 = validateParameter(valid_603121, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_603121 != nil:
    section.add "X-Amz-Target", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Algorithm")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Algorithm", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603128: Call_UntagResources_603116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_603128.validator(path, query, header, formData, body)
  let scheme = call_603128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603128.url(scheme.get, call_603128.host, call_603128.base,
                         call_603128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603128, url, valid)

proc call*(call_603129: Call_UntagResources_603116; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603130 = newJObject()
  if body != nil:
    body_603130 = body
  result = call_603129.call(nil, nil, nil, nil, body_603130)

var untagResources* = Call_UntagResources_603116(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_603117, base: "/", url: url_UntagResources_603118,
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
