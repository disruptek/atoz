
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetResources_602757 = ref object of OpenApiRestCall_602420
proc url_GetResources_602759(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResources_602758(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602871 = query.getOrDefault("ResourcesPerPage")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "ResourcesPerPage", valid_602871
  var valid_602872 = query.getOrDefault("PaginationToken")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "PaginationToken", valid_602872
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
  var valid_602873 = header.getOrDefault("X-Amz-Date")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Date", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Security-Token")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Security-Token", valid_602874
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602888 = header.getOrDefault("X-Amz-Target")
  valid_602888 = validateParameter(valid_602888, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_602888 != nil:
    section.add "X-Amz-Target", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Content-Sha256", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Algorithm")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Algorithm", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Signature")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Signature", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-SignedHeaders", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Credential")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Credential", valid_602893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_GetResources_602757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"))
  result = hook(call_602917, url, valid)

proc call*(call_602988: Call_GetResources_602757; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_602989 = newJObject()
  var body_602991 = newJObject()
  add(query_602989, "ResourcesPerPage", newJString(ResourcesPerPage))
  add(query_602989, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_602991 = body
  result = call_602988.call(nil, query_602989, nil, nil, body_602991)

var getResources* = Call_GetResources_602757(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_602758, base: "/", url: url_GetResources_602759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_603030 = ref object of OpenApiRestCall_602420
proc url_GetTagKeys_603032(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagKeys_603031(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603033 = query.getOrDefault("PaginationToken")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "PaginationToken", valid_603033
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
  var valid_603034 = header.getOrDefault("X-Amz-Date")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Date", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Security-Token")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Security-Token", valid_603035
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603036 = header.getOrDefault("X-Amz-Target")
  valid_603036 = validateParameter(valid_603036, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_603036 != nil:
    section.add "X-Amz-Target", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Content-Sha256", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Algorithm")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Algorithm", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Signature")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Signature", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-SignedHeaders", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Credential")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Credential", valid_603041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603043: Call_GetTagKeys_603030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  let valid = call_603043.validator(path, query, header, formData, body)
  let scheme = call_603043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603043.url(scheme.get, call_603043.host, call_603043.base,
                         call_603043.route, valid.getOrDefault("path"))
  result = hook(call_603043, url, valid)

proc call*(call_603044: Call_GetTagKeys_603030; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_603045 = newJObject()
  var body_603046 = newJObject()
  add(query_603045, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_603046 = body
  result = call_603044.call(nil, query_603045, nil, nil, body_603046)

var getTagKeys* = Call_GetTagKeys_603030(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_603031,
                                      base: "/", url: url_GetTagKeys_603032,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_603047 = ref object of OpenApiRestCall_602420
proc url_GetTagValues_603049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagValues_603048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603050 = query.getOrDefault("PaginationToken")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "PaginationToken", valid_603050
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
  var valid_603051 = header.getOrDefault("X-Amz-Date")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Date", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Security-Token")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Security-Token", valid_603052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603053 = header.getOrDefault("X-Amz-Target")
  valid_603053 = validateParameter(valid_603053, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_603053 != nil:
    section.add "X-Amz-Target", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Content-Sha256", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Algorithm")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Algorithm", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Signature")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Signature", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-SignedHeaders", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Credential")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Credential", valid_603058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603060: Call_GetTagValues_603047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  let valid = call_603060.validator(path, query, header, formData, body)
  let scheme = call_603060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603060.url(scheme.get, call_603060.host, call_603060.base,
                         call_603060.route, valid.getOrDefault("path"))
  result = hook(call_603060, url, valid)

proc call*(call_603061: Call_GetTagValues_603047; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_603062 = newJObject()
  var body_603063 = newJObject()
  add(query_603062, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_603063 = body
  result = call_603061.call(nil, query_603062, nil, nil, body_603063)

var getTagValues* = Call_GetTagValues_603047(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_603048, base: "/", url: url_GetTagValues_603049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_603064 = ref object of OpenApiRestCall_602420
proc url_TagResources_603066(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResources_603065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603067 = header.getOrDefault("X-Amz-Date")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Date", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603069 = header.getOrDefault("X-Amz-Target")
  valid_603069 = validateParameter(valid_603069, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_603069 != nil:
    section.add "X-Amz-Target", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Content-Sha256", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Algorithm")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Algorithm", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Signature")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Signature", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-SignedHeaders", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Credential")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Credential", valid_603074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603076: Call_TagResources_603064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_603076.validator(path, query, header, formData, body)
  let scheme = call_603076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603076.url(scheme.get, call_603076.host, call_603076.base,
                         call_603076.route, valid.getOrDefault("path"))
  result = hook(call_603076, url, valid)

proc call*(call_603077: Call_TagResources_603064; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603078 = newJObject()
  if body != nil:
    body_603078 = body
  result = call_603077.call(nil, nil, nil, nil, body_603078)

var tagResources* = Call_TagResources_603064(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_603065, base: "/", url: url_TagResources_603066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_603079 = ref object of OpenApiRestCall_602420
proc url_UntagResources_603081(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResources_603080(path: JsonNode; query: JsonNode;
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
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603084 = header.getOrDefault("X-Amz-Target")
  valid_603084 = validateParameter(valid_603084, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_603084 != nil:
    section.add "X-Amz-Target", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Content-Sha256", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Algorithm")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Algorithm", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Signature")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Signature", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-SignedHeaders", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Credential")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Credential", valid_603089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_UntagResources_603079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"))
  result = hook(call_603091, url, valid)

proc call*(call_603092: Call_UntagResources_603079; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603093 = newJObject()
  if body != nil:
    body_603093 = body
  result = call_603092.call(nil, nil, nil, nil, body_603093)

var untagResources* = Call_UntagResources_603079(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_603080, base: "/", url: url_UntagResources_603081,
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
