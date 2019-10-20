
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeDeploy
## version: 2014-10-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeDeploy</fullname> <p>AWS CodeDeploy is a deployment service that automates application deployments to Amazon EC2 instances, on-premises instances running in your own facility, serverless AWS Lambda functions, or applications in an Amazon ECS service.</p> <p>You can deploy a nearly unlimited variety of application content, such as an updated Lambda function, updated applications in an Amazon ECS service, code, web and configuration files, executables, packages, scripts, multimedia files, and so on. AWS CodeDeploy can deploy application content stored in Amazon S3 buckets, GitHub repositories, or Bitbucket repositories. You do not need to make changes to your existing code before you can use AWS CodeDeploy.</p> <p>AWS CodeDeploy makes it easier for you to rapidly release new features, helps you avoid downtime during application deployment, and handles the complexity of updating your applications, without many of the risks associated with error-prone manual deployments.</p> <p> <b>AWS CodeDeploy Components</b> </p> <p>Use the information in this guide to help you work with the following AWS CodeDeploy components:</p> <ul> <li> <p> <b>Application</b>: A name that uniquely identifies the application you want to deploy. AWS CodeDeploy uses this name, which functions as a container, to ensure the correct combination of revision, deployment configuration, and deployment group are referenced during a deployment.</p> </li> <li> <p> <b>Deployment group</b>: A set of individual instances, CodeDeploy Lambda deployment configuration settings, or an Amazon ECS service and network details. A Lambda deployment group specifies how to route traffic to a new version of a Lambda function. An Amazon ECS deployment group specifies the service created in Amazon ECS to deploy, a load balancer, and a listener to reroute production traffic to an updated containerized application. An EC2/On-premises deployment group contains individually tagged instances, Amazon EC2 instances in Amazon EC2 Auto Scaling groups, or both. All deployment groups can specify optional trigger, alarm, and rollback settings.</p> </li> <li> <p> <b>Deployment configuration</b>: A set of deployment rules and deployment success and failure conditions used by AWS CodeDeploy during a deployment.</p> </li> <li> <p> <b>Deployment</b>: The process and the components used when updating a Lambda function, a containerized application in an Amazon ECS service, or of installing content on one or more instances. </p> </li> <li> <p> <b>Application revisions</b>: For an AWS Lambda deployment, this is an AppSpec file that specifies the Lambda function to be updated and one or more functions to validate deployment lifecycle events. For an Amazon ECS deployment, this is an AppSpec file that specifies the Amazon ECS task definition, container, and port where production traffic is rerouted. For an EC2/On-premises deployment, this is an archive file that contains source content—source code, webpages, executable files, and deployment scripts—along with an AppSpec file. Revisions are stored in Amazon S3 buckets or GitHub repositories. For Amazon S3, a revision is uniquely identified by its Amazon S3 object key and its ETag, version, or both. For GitHub, a revision is uniquely identified by its commit ID.</p> </li> </ul> <p>This guide also contains information to help you get details about the instances in your deployments, to make on-premises instances available for AWS CodeDeploy deployments, to get details about a Lambda function deployment, and to get details about Amazon ECS service deployments.</p> <p> <b>AWS CodeDeploy Information Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/codedeploy/latest/userguide">AWS CodeDeploy User Guide</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/">AWS CodeDeploy API Reference Guide</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/cli/latest/reference/deploy/index.html">AWS CLI Reference for AWS CodeDeploy</a> </p> </li> <li> <p> <a href="https://forums.aws.amazon.com/forum.jspa?forumID=179">AWS CodeDeploy Developer Forum</a> </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codedeploy/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codedeploy.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codedeploy.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codedeploy.us-west-2.amazonaws.com",
                           "eu-west-2": "codedeploy.eu-west-2.amazonaws.com", "ap-northeast-3": "codedeploy.ap-northeast-3.amazonaws.com", "eu-central-1": "codedeploy.eu-central-1.amazonaws.com",
                           "us-east-2": "codedeploy.us-east-2.amazonaws.com",
                           "us-east-1": "codedeploy.us-east-1.amazonaws.com", "cn-northwest-1": "codedeploy.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codedeploy.ap-south-1.amazonaws.com",
                           "eu-north-1": "codedeploy.eu-north-1.amazonaws.com", "ap-northeast-2": "codedeploy.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codedeploy.us-west-1.amazonaws.com", "us-gov-east-1": "codedeploy.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codedeploy.eu-west-3.amazonaws.com", "cn-north-1": "codedeploy.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codedeploy.sa-east-1.amazonaws.com",
                           "eu-west-1": "codedeploy.eu-west-1.amazonaws.com", "us-gov-west-1": "codedeploy.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codedeploy.ap-southeast-2.amazonaws.com", "ca-central-1": "codedeploy.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codedeploy.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codedeploy.ap-southeast-1.amazonaws.com",
      "us-west-2": "codedeploy.us-west-2.amazonaws.com",
      "eu-west-2": "codedeploy.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codedeploy.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codedeploy.eu-central-1.amazonaws.com",
      "us-east-2": "codedeploy.us-east-2.amazonaws.com",
      "us-east-1": "codedeploy.us-east-1.amazonaws.com",
      "cn-northwest-1": "codedeploy.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codedeploy.ap-south-1.amazonaws.com",
      "eu-north-1": "codedeploy.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codedeploy.ap-northeast-2.amazonaws.com",
      "us-west-1": "codedeploy.us-west-1.amazonaws.com",
      "us-gov-east-1": "codedeploy.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codedeploy.eu-west-3.amazonaws.com",
      "cn-north-1": "codedeploy.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codedeploy.sa-east-1.amazonaws.com",
      "eu-west-1": "codedeploy.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codedeploy.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codedeploy.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codedeploy.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codedeploy"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToOnPremisesInstances_592703 = ref object of OpenApiRestCall_592364
proc url_AddTagsToOnPremisesInstances_592705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToOnPremisesInstances_592704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to on-premises instances.
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
      "CodeDeploy_20141006.AddTagsToOnPremisesInstances"))
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

proc call*(call_592861: Call_AddTagsToOnPremisesInstances_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to on-premises instances.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_AddTagsToOnPremisesInstances_592703; body: JsonNode): Recallable =
  ## addTagsToOnPremisesInstances
  ## Adds tags to on-premises instances.
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var addTagsToOnPremisesInstances* = Call_AddTagsToOnPremisesInstances_592703(
    name: "addTagsToOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.AddTagsToOnPremisesInstances",
    validator: validate_AddTagsToOnPremisesInstances_592704, base: "/",
    url: url_AddTagsToOnPremisesInstances_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplicationRevisions_592972 = ref object of OpenApiRestCall_592364
proc url_BatchGetApplicationRevisions_592974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetApplicationRevisions_592973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
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
      "CodeDeploy_20141006.BatchGetApplicationRevisions"))
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

proc call*(call_592984: Call_BatchGetApplicationRevisions_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_BatchGetApplicationRevisions_592972; body: JsonNode): Recallable =
  ## batchGetApplicationRevisions
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var batchGetApplicationRevisions* = Call_BatchGetApplicationRevisions_592972(
    name: "batchGetApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplicationRevisions",
    validator: validate_BatchGetApplicationRevisions_592973, base: "/",
    url: url_BatchGetApplicationRevisions_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplications_592987 = ref object of OpenApiRestCall_592364
proc url_BatchGetApplications_592989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetApplications_592988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
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
      "CodeDeploy_20141006.BatchGetApplications"))
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

proc call*(call_592999: Call_BatchGetApplications_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_BatchGetApplications_592987; body: JsonNode): Recallable =
  ## batchGetApplications
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var batchGetApplications* = Call_BatchGetApplications_592987(
    name: "batchGetApplications", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplications",
    validator: validate_BatchGetApplications_592988, base: "/",
    url: url_BatchGetApplications_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentGroups_593002 = ref object of OpenApiRestCall_592364
proc url_BatchGetDeploymentGroups_593004(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDeploymentGroups_593003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more deployment groups.
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
      "CodeDeploy_20141006.BatchGetDeploymentGroups"))
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

proc call*(call_593014: Call_BatchGetDeploymentGroups_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployment groups.
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_BatchGetDeploymentGroups_593002; body: JsonNode): Recallable =
  ## batchGetDeploymentGroups
  ## Gets information about one or more deployment groups.
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var batchGetDeploymentGroups* = Call_BatchGetDeploymentGroups_593002(
    name: "batchGetDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentGroups",
    validator: validate_BatchGetDeploymentGroups_593003, base: "/",
    url: url_BatchGetDeploymentGroups_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentInstances_593017 = ref object of OpenApiRestCall_592364
proc url_BatchGetDeploymentInstances_593019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDeploymentInstances_593018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
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
      "CodeDeploy_20141006.BatchGetDeploymentInstances"))
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

proc call*(call_593029: Call_BatchGetDeploymentInstances_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_BatchGetDeploymentInstances_593017; body: JsonNode): Recallable =
  ## batchGetDeploymentInstances
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var batchGetDeploymentInstances* = Call_BatchGetDeploymentInstances_593017(
    name: "batchGetDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentInstances",
    validator: validate_BatchGetDeploymentInstances_593018, base: "/",
    url: url_BatchGetDeploymentInstances_593019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentTargets_593032 = ref object of OpenApiRestCall_592364
proc url_BatchGetDeploymentTargets_593034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDeploymentTargets_593033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
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
      "CodeDeploy_20141006.BatchGetDeploymentTargets"))
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

proc call*(call_593044: Call_BatchGetDeploymentTargets_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_BatchGetDeploymentTargets_593032; body: JsonNode): Recallable =
  ## batchGetDeploymentTargets
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var batchGetDeploymentTargets* = Call_BatchGetDeploymentTargets_593032(
    name: "batchGetDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentTargets",
    validator: validate_BatchGetDeploymentTargets_593033, base: "/",
    url: url_BatchGetDeploymentTargets_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeployments_593047 = ref object of OpenApiRestCall_592364
proc url_BatchGetDeployments_593049(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDeployments_593048(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
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
      "CodeDeploy_20141006.BatchGetDeployments"))
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

proc call*(call_593059: Call_BatchGetDeployments_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_BatchGetDeployments_593047; body: JsonNode): Recallable =
  ## batchGetDeployments
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var batchGetDeployments* = Call_BatchGetDeployments_593047(
    name: "batchGetDeployments", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeployments",
    validator: validate_BatchGetDeployments_593048, base: "/",
    url: url_BatchGetDeployments_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetOnPremisesInstances_593062 = ref object of OpenApiRestCall_592364
proc url_BatchGetOnPremisesInstances_593064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetOnPremisesInstances_593063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
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
      "CodeDeploy_20141006.BatchGetOnPremisesInstances"))
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

proc call*(call_593074: Call_BatchGetOnPremisesInstances_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_BatchGetOnPremisesInstances_593062; body: JsonNode): Recallable =
  ## batchGetOnPremisesInstances
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var batchGetOnPremisesInstances* = Call_BatchGetOnPremisesInstances_593062(
    name: "batchGetOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetOnPremisesInstances",
    validator: validate_BatchGetOnPremisesInstances_593063, base: "/",
    url: url_BatchGetOnPremisesInstances_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ContinueDeployment_593077 = ref object of OpenApiRestCall_592364
proc url_ContinueDeployment_593079(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ContinueDeployment_593078(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
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
      "CodeDeploy_20141006.ContinueDeployment"))
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

proc call*(call_593089: Call_ContinueDeployment_593077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_ContinueDeployment_593077; body: JsonNode): Recallable =
  ## continueDeployment
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var continueDeployment* = Call_ContinueDeployment_593077(
    name: "continueDeployment", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ContinueDeployment",
    validator: validate_ContinueDeployment_593078, base: "/",
    url: url_ContinueDeployment_593079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_593092 = ref object of OpenApiRestCall_592364
proc url_CreateApplication_593094(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApplication_593093(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an application.
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
      "CodeDeploy_20141006.CreateApplication"))
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

proc call*(call_593104: Call_CreateApplication_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_CreateApplication_593092; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application.
  ##   body: JObject (required)
  var body_593106 = newJObject()
  if body != nil:
    body_593106 = body
  result = call_593105.call(nil, nil, nil, nil, body_593106)

var createApplication* = Call_CreateApplication_593092(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateApplication",
    validator: validate_CreateApplication_593093, base: "/",
    url: url_CreateApplication_593094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_593107 = ref object of OpenApiRestCall_592364
proc url_CreateDeployment_593109(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeployment_593108(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deploys an application revision through the specified deployment group.
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
      "CodeDeploy_20141006.CreateDeployment"))
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

proc call*(call_593119: Call_CreateDeployment_593107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys an application revision through the specified deployment group.
  ## 
  let valid = call_593119.validator(path, query, header, formData, body)
  let scheme = call_593119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593119.url(scheme.get, call_593119.host, call_593119.base,
                         call_593119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593119, url, valid)

proc call*(call_593120: Call_CreateDeployment_593107; body: JsonNode): Recallable =
  ## createDeployment
  ## Deploys an application revision through the specified deployment group.
  ##   body: JObject (required)
  var body_593121 = newJObject()
  if body != nil:
    body_593121 = body
  result = call_593120.call(nil, nil, nil, nil, body_593121)

var createDeployment* = Call_CreateDeployment_593107(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeployment",
    validator: validate_CreateDeployment_593108, base: "/",
    url: url_CreateDeployment_593109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentConfig_593122 = ref object of OpenApiRestCall_592364
proc url_CreateDeploymentConfig_593124(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeploymentConfig_593123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a deployment configuration. 
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
      "CodeDeploy_20141006.CreateDeploymentConfig"))
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

proc call*(call_593134: Call_CreateDeploymentConfig_593122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a deployment configuration. 
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_CreateDeploymentConfig_593122; body: JsonNode): Recallable =
  ## createDeploymentConfig
  ##  Creates a deployment configuration. 
  ##   body: JObject (required)
  var body_593136 = newJObject()
  if body != nil:
    body_593136 = body
  result = call_593135.call(nil, nil, nil, nil, body_593136)

var createDeploymentConfig* = Call_CreateDeploymentConfig_593122(
    name: "createDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentConfig",
    validator: validate_CreateDeploymentConfig_593123, base: "/",
    url: url_CreateDeploymentConfig_593124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentGroup_593137 = ref object of OpenApiRestCall_592364
proc url_CreateDeploymentGroup_593139(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeploymentGroup_593138(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a deployment group to which application revisions are deployed.
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
      "CodeDeploy_20141006.CreateDeploymentGroup"))
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

proc call*(call_593149: Call_CreateDeploymentGroup_593137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment group to which application revisions are deployed.
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_CreateDeploymentGroup_593137; body: JsonNode): Recallable =
  ## createDeploymentGroup
  ## Creates a deployment group to which application revisions are deployed.
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var createDeploymentGroup* = Call_CreateDeploymentGroup_593137(
    name: "createDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentGroup",
    validator: validate_CreateDeploymentGroup_593138, base: "/",
    url: url_CreateDeploymentGroup_593139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_593152 = ref object of OpenApiRestCall_592364
proc url_DeleteApplication_593154(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplication_593153(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an application.
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
      "CodeDeploy_20141006.DeleteApplication"))
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

proc call*(call_593164: Call_DeleteApplication_593152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_DeleteApplication_593152; body: JsonNode): Recallable =
  ## deleteApplication
  ## Deletes an application.
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var deleteApplication* = Call_DeleteApplication_593152(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteApplication",
    validator: validate_DeleteApplication_593153, base: "/",
    url: url_DeleteApplication_593154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentConfig_593167 = ref object of OpenApiRestCall_592364
proc url_DeleteDeploymentConfig_593169(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeploymentConfig_593168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
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
      "CodeDeploy_20141006.DeleteDeploymentConfig"))
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

proc call*(call_593179: Call_DeleteDeploymentConfig_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_DeleteDeploymentConfig_593167; body: JsonNode): Recallable =
  ## deleteDeploymentConfig
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var deleteDeploymentConfig* = Call_DeleteDeploymentConfig_593167(
    name: "deleteDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentConfig",
    validator: validate_DeleteDeploymentConfig_593168, base: "/",
    url: url_DeleteDeploymentConfig_593169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentGroup_593182 = ref object of OpenApiRestCall_592364
proc url_DeleteDeploymentGroup_593184(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeploymentGroup_593183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a deployment group.
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
      "CodeDeploy_20141006.DeleteDeploymentGroup"))
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

proc call*(call_593194: Call_DeleteDeploymentGroup_593182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a deployment group.
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_DeleteDeploymentGroup_593182; body: JsonNode): Recallable =
  ## deleteDeploymentGroup
  ## Deletes a deployment group.
  ##   body: JObject (required)
  var body_593196 = newJObject()
  if body != nil:
    body_593196 = body
  result = call_593195.call(nil, nil, nil, nil, body_593196)

var deleteDeploymentGroup* = Call_DeleteDeploymentGroup_593182(
    name: "deleteDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentGroup",
    validator: validate_DeleteDeploymentGroup_593183, base: "/",
    url: url_DeleteDeploymentGroup_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGitHubAccountToken_593197 = ref object of OpenApiRestCall_592364
proc url_DeleteGitHubAccountToken_593199(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGitHubAccountToken_593198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a GitHub account connection.
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
      "CodeDeploy_20141006.DeleteGitHubAccountToken"))
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

proc call*(call_593209: Call_DeleteGitHubAccountToken_593197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a GitHub account connection.
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_DeleteGitHubAccountToken_593197; body: JsonNode): Recallable =
  ## deleteGitHubAccountToken
  ## Deletes a GitHub account connection.
  ##   body: JObject (required)
  var body_593211 = newJObject()
  if body != nil:
    body_593211 = body
  result = call_593210.call(nil, nil, nil, nil, body_593211)

var deleteGitHubAccountToken* = Call_DeleteGitHubAccountToken_593197(
    name: "deleteGitHubAccountToken", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteGitHubAccountToken",
    validator: validate_DeleteGitHubAccountToken_593198, base: "/",
    url: url_DeleteGitHubAccountToken_593199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterOnPremisesInstance_593212 = ref object of OpenApiRestCall_592364
proc url_DeregisterOnPremisesInstance_593214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterOnPremisesInstance_593213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters an on-premises instance.
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
      "CodeDeploy_20141006.DeregisterOnPremisesInstance"))
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

proc call*(call_593224: Call_DeregisterOnPremisesInstance_593212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an on-premises instance.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_DeregisterOnPremisesInstance_593212; body: JsonNode): Recallable =
  ## deregisterOnPremisesInstance
  ## Deregisters an on-premises instance.
  ##   body: JObject (required)
  var body_593226 = newJObject()
  if body != nil:
    body_593226 = body
  result = call_593225.call(nil, nil, nil, nil, body_593226)

var deregisterOnPremisesInstance* = Call_DeregisterOnPremisesInstance_593212(
    name: "deregisterOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeregisterOnPremisesInstance",
    validator: validate_DeregisterOnPremisesInstance_593213, base: "/",
    url: url_DeregisterOnPremisesInstance_593214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_593227 = ref object of OpenApiRestCall_592364
proc url_GetApplication_593229(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplication_593228(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about an application.
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
      "CodeDeploy_20141006.GetApplication"))
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

proc call*(call_593239: Call_GetApplication_593227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application.
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_GetApplication_593227; body: JsonNode): Recallable =
  ## getApplication
  ## Gets information about an application.
  ##   body: JObject (required)
  var body_593241 = newJObject()
  if body != nil:
    body_593241 = body
  result = call_593240.call(nil, nil, nil, nil, body_593241)

var getApplication* = Call_GetApplication_593227(name: "getApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplication",
    validator: validate_GetApplication_593228, base: "/", url: url_GetApplication_593229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationRevision_593242 = ref object of OpenApiRestCall_592364
proc url_GetApplicationRevision_593244(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplicationRevision_593243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an application revision.
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
      "CodeDeploy_20141006.GetApplicationRevision"))
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

proc call*(call_593254: Call_GetApplicationRevision_593242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application revision.
  ## 
  let valid = call_593254.validator(path, query, header, formData, body)
  let scheme = call_593254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593254.url(scheme.get, call_593254.host, call_593254.base,
                         call_593254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593254, url, valid)

proc call*(call_593255: Call_GetApplicationRevision_593242; body: JsonNode): Recallable =
  ## getApplicationRevision
  ## Gets information about an application revision.
  ##   body: JObject (required)
  var body_593256 = newJObject()
  if body != nil:
    body_593256 = body
  result = call_593255.call(nil, nil, nil, nil, body_593256)

var getApplicationRevision* = Call_GetApplicationRevision_593242(
    name: "getApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplicationRevision",
    validator: validate_GetApplicationRevision_593243, base: "/",
    url: url_GetApplicationRevision_593244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_593257 = ref object of OpenApiRestCall_592364
proc url_GetDeployment_593259(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeployment_593258(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
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
      "CodeDeploy_20141006.GetDeployment"))
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

proc call*(call_593269: Call_GetDeployment_593257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ## 
  let valid = call_593269.validator(path, query, header, formData, body)
  let scheme = call_593269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593269.url(scheme.get, call_593269.host, call_593269.base,
                         call_593269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593269, url, valid)

proc call*(call_593270: Call_GetDeployment_593257; body: JsonNode): Recallable =
  ## getDeployment
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ##   body: JObject (required)
  var body_593271 = newJObject()
  if body != nil:
    body_593271 = body
  result = call_593270.call(nil, nil, nil, nil, body_593271)

var getDeployment* = Call_GetDeployment_593257(name: "getDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeployment",
    validator: validate_GetDeployment_593258, base: "/", url: url_GetDeployment_593259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentConfig_593272 = ref object of OpenApiRestCall_592364
proc url_GetDeploymentConfig_593274(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeploymentConfig_593273(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about a deployment configuration.
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
      "CodeDeploy_20141006.GetDeploymentConfig"))
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

proc call*(call_593284: Call_GetDeploymentConfig_593272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment configuration.
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_GetDeploymentConfig_593272; body: JsonNode): Recallable =
  ## getDeploymentConfig
  ## Gets information about a deployment configuration.
  ##   body: JObject (required)
  var body_593286 = newJObject()
  if body != nil:
    body_593286 = body
  result = call_593285.call(nil, nil, nil, nil, body_593286)

var getDeploymentConfig* = Call_GetDeploymentConfig_593272(
    name: "getDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentConfig",
    validator: validate_GetDeploymentConfig_593273, base: "/",
    url: url_GetDeploymentConfig_593274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentGroup_593287 = ref object of OpenApiRestCall_592364
proc url_GetDeploymentGroup_593289(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeploymentGroup_593288(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about a deployment group.
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
      "CodeDeploy_20141006.GetDeploymentGroup"))
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

proc call*(call_593299: Call_GetDeploymentGroup_593287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment group.
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_GetDeploymentGroup_593287; body: JsonNode): Recallable =
  ## getDeploymentGroup
  ## Gets information about a deployment group.
  ##   body: JObject (required)
  var body_593301 = newJObject()
  if body != nil:
    body_593301 = body
  result = call_593300.call(nil, nil, nil, nil, body_593301)

var getDeploymentGroup* = Call_GetDeploymentGroup_593287(
    name: "getDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentGroup",
    validator: validate_GetDeploymentGroup_593288, base: "/",
    url: url_GetDeploymentGroup_593289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentInstance_593302 = ref object of OpenApiRestCall_592364
proc url_GetDeploymentInstance_593304(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeploymentInstance_593303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an instance as part of a deployment.
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
      "CodeDeploy_20141006.GetDeploymentInstance"))
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

proc call*(call_593314: Call_GetDeploymentInstance_593302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an instance as part of a deployment.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_GetDeploymentInstance_593302; body: JsonNode): Recallable =
  ## getDeploymentInstance
  ## Gets information about an instance as part of a deployment.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var getDeploymentInstance* = Call_GetDeploymentInstance_593302(
    name: "getDeploymentInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentInstance",
    validator: validate_GetDeploymentInstance_593303, base: "/",
    url: url_GetDeploymentInstance_593304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentTarget_593317 = ref object of OpenApiRestCall_592364
proc url_GetDeploymentTarget_593319(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeploymentTarget_593318(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Returns information about a deployment target. 
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
      "CodeDeploy_20141006.GetDeploymentTarget"))
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

proc call*(call_593329: Call_GetDeploymentTarget_593317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about a deployment target. 
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_GetDeploymentTarget_593317; body: JsonNode): Recallable =
  ## getDeploymentTarget
  ##  Returns information about a deployment target. 
  ##   body: JObject (required)
  var body_593331 = newJObject()
  if body != nil:
    body_593331 = body
  result = call_593330.call(nil, nil, nil, nil, body_593331)

var getDeploymentTarget* = Call_GetDeploymentTarget_593317(
    name: "getDeploymentTarget", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentTarget",
    validator: validate_GetDeploymentTarget_593318, base: "/",
    url: url_GetDeploymentTarget_593319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOnPremisesInstance_593332 = ref object of OpenApiRestCall_592364
proc url_GetOnPremisesInstance_593334(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOnPremisesInstance_593333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets information about an on-premises instance. 
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
      "CodeDeploy_20141006.GetOnPremisesInstance"))
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

proc call*(call_593344: Call_GetOnPremisesInstance_593332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets information about an on-premises instance. 
  ## 
  let valid = call_593344.validator(path, query, header, formData, body)
  let scheme = call_593344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593344.url(scheme.get, call_593344.host, call_593344.base,
                         call_593344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593344, url, valid)

proc call*(call_593345: Call_GetOnPremisesInstance_593332; body: JsonNode): Recallable =
  ## getOnPremisesInstance
  ##  Gets information about an on-premises instance. 
  ##   body: JObject (required)
  var body_593346 = newJObject()
  if body != nil:
    body_593346 = body
  result = call_593345.call(nil, nil, nil, nil, body_593346)

var getOnPremisesInstance* = Call_GetOnPremisesInstance_593332(
    name: "getOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetOnPremisesInstance",
    validator: validate_GetOnPremisesInstance_593333, base: "/",
    url: url_GetOnPremisesInstance_593334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationRevisions_593347 = ref object of OpenApiRestCall_592364
proc url_ListApplicationRevisions_593349(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApplicationRevisions_593348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about revisions for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593350 = query.getOrDefault("nextToken")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "nextToken", valid_593350
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
  var valid_593351 = header.getOrDefault("X-Amz-Target")
  valid_593351 = validateParameter(valid_593351, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplicationRevisions"))
  if valid_593351 != nil:
    section.add "X-Amz-Target", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Signature")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Signature", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Content-Sha256", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Date")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Date", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Credential")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Credential", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Security-Token")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Security-Token", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Algorithm")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Algorithm", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-SignedHeaders", valid_593358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593360: Call_ListApplicationRevisions_593347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about revisions for an application.
  ## 
  let valid = call_593360.validator(path, query, header, formData, body)
  let scheme = call_593360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593360.url(scheme.get, call_593360.host, call_593360.base,
                         call_593360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593360, url, valid)

proc call*(call_593361: Call_ListApplicationRevisions_593347; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplicationRevisions
  ## Lists information about revisions for an application.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593362 = newJObject()
  var body_593363 = newJObject()
  add(query_593362, "nextToken", newJString(nextToken))
  if body != nil:
    body_593363 = body
  result = call_593361.call(nil, query_593362, nil, nil, body_593363)

var listApplicationRevisions* = Call_ListApplicationRevisions_593347(
    name: "listApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplicationRevisions",
    validator: validate_ListApplicationRevisions_593348, base: "/",
    url: url_ListApplicationRevisions_593349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_593365 = ref object of OpenApiRestCall_592364
proc url_ListApplications_593367(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApplications_593366(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593368 = query.getOrDefault("nextToken")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "nextToken", valid_593368
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
  var valid_593369 = header.getOrDefault("X-Amz-Target")
  valid_593369 = validateParameter(valid_593369, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplications"))
  if valid_593369 != nil:
    section.add "X-Amz-Target", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Signature")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Signature", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Content-Sha256", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Date")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Date", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Credential")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Credential", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Security-Token")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Security-Token", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Algorithm")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Algorithm", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-SignedHeaders", valid_593376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593378: Call_ListApplications_593365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  let valid = call_593378.validator(path, query, header, formData, body)
  let scheme = call_593378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593378.url(scheme.get, call_593378.host, call_593378.base,
                         call_593378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593378, url, valid)

proc call*(call_593379: Call_ListApplications_593365; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the applications registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593380 = newJObject()
  var body_593381 = newJObject()
  add(query_593380, "nextToken", newJString(nextToken))
  if body != nil:
    body_593381 = body
  result = call_593379.call(nil, query_593380, nil, nil, body_593381)

var listApplications* = Call_ListApplications_593365(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplications",
    validator: validate_ListApplications_593366, base: "/",
    url: url_ListApplications_593367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentConfigs_593382 = ref object of OpenApiRestCall_592364
proc url_ListDeploymentConfigs_593384(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentConfigs_593383(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593385 = query.getOrDefault("nextToken")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "nextToken", valid_593385
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
  var valid_593386 = header.getOrDefault("X-Amz-Target")
  valid_593386 = validateParameter(valid_593386, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentConfigs"))
  if valid_593386 != nil:
    section.add "X-Amz-Target", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Signature")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Signature", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Content-Sha256", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Date")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Date", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Credential")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Credential", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Security-Token")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Security-Token", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Algorithm")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Algorithm", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-SignedHeaders", valid_593393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593395: Call_ListDeploymentConfigs_593382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  let valid = call_593395.validator(path, query, header, formData, body)
  let scheme = call_593395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593395.url(scheme.get, call_593395.host, call_593395.base,
                         call_593395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593395, url, valid)

proc call*(call_593396: Call_ListDeploymentConfigs_593382; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentConfigs
  ## Lists the deployment configurations with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593397 = newJObject()
  var body_593398 = newJObject()
  add(query_593397, "nextToken", newJString(nextToken))
  if body != nil:
    body_593398 = body
  result = call_593396.call(nil, query_593397, nil, nil, body_593398)

var listDeploymentConfigs* = Call_ListDeploymentConfigs_593382(
    name: "listDeploymentConfigs", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentConfigs",
    validator: validate_ListDeploymentConfigs_593383, base: "/",
    url: url_ListDeploymentConfigs_593384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentGroups_593399 = ref object of OpenApiRestCall_592364
proc url_ListDeploymentGroups_593401(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentGroups_593400(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593402 = query.getOrDefault("nextToken")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "nextToken", valid_593402
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
  var valid_593403 = header.getOrDefault("X-Amz-Target")
  valid_593403 = validateParameter(valid_593403, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentGroups"))
  if valid_593403 != nil:
    section.add "X-Amz-Target", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Signature")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Signature", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Content-Sha256", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Date")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Date", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Credential")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Credential", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Security-Token")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Security-Token", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Algorithm")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Algorithm", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-SignedHeaders", valid_593410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593412: Call_ListDeploymentGroups_593399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_593412.validator(path, query, header, formData, body)
  let scheme = call_593412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593412.url(scheme.get, call_593412.host, call_593412.base,
                         call_593412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593412, url, valid)

proc call*(call_593413: Call_ListDeploymentGroups_593399; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentGroups
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593414 = newJObject()
  var body_593415 = newJObject()
  add(query_593414, "nextToken", newJString(nextToken))
  if body != nil:
    body_593415 = body
  result = call_593413.call(nil, query_593414, nil, nil, body_593415)

var listDeploymentGroups* = Call_ListDeploymentGroups_593399(
    name: "listDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentGroups",
    validator: validate_ListDeploymentGroups_593400, base: "/",
    url: url_ListDeploymentGroups_593401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentInstances_593416 = ref object of OpenApiRestCall_592364
proc url_ListDeploymentInstances_593418(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentInstances_593417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593419 = query.getOrDefault("nextToken")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "nextToken", valid_593419
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
  var valid_593420 = header.getOrDefault("X-Amz-Target")
  valid_593420 = validateParameter(valid_593420, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentInstances"))
  if valid_593420 != nil:
    section.add "X-Amz-Target", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Signature")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Signature", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Content-Sha256", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Date")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Date", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Credential")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Credential", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Security-Token")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Security-Token", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Algorithm")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Algorithm", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-SignedHeaders", valid_593427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593429: Call_ListDeploymentInstances_593416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  let valid = call_593429.validator(path, query, header, formData, body)
  let scheme = call_593429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593429.url(scheme.get, call_593429.host, call_593429.base,
                         call_593429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593429, url, valid)

proc call*(call_593430: Call_ListDeploymentInstances_593416; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentInstances
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593431 = newJObject()
  var body_593432 = newJObject()
  add(query_593431, "nextToken", newJString(nextToken))
  if body != nil:
    body_593432 = body
  result = call_593430.call(nil, query_593431, nil, nil, body_593432)

var listDeploymentInstances* = Call_ListDeploymentInstances_593416(
    name: "listDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentInstances",
    validator: validate_ListDeploymentInstances_593417, base: "/",
    url: url_ListDeploymentInstances_593418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentTargets_593433 = ref object of OpenApiRestCall_592364
proc url_ListDeploymentTargets_593435(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentTargets_593434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns an array of target IDs that are associated a deployment. 
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
  var valid_593436 = header.getOrDefault("X-Amz-Target")
  valid_593436 = validateParameter(valid_593436, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentTargets"))
  if valid_593436 != nil:
    section.add "X-Amz-Target", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Signature")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Signature", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Content-Sha256", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Date")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Date", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Credential")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Credential", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Security-Token")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Security-Token", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Algorithm")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Algorithm", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-SignedHeaders", valid_593443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593445: Call_ListDeploymentTargets_593433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of target IDs that are associated a deployment. 
  ## 
  let valid = call_593445.validator(path, query, header, formData, body)
  let scheme = call_593445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593445.url(scheme.get, call_593445.host, call_593445.base,
                         call_593445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593445, url, valid)

proc call*(call_593446: Call_ListDeploymentTargets_593433; body: JsonNode): Recallable =
  ## listDeploymentTargets
  ##  Returns an array of target IDs that are associated a deployment. 
  ##   body: JObject (required)
  var body_593447 = newJObject()
  if body != nil:
    body_593447 = body
  result = call_593446.call(nil, nil, nil, nil, body_593447)

var listDeploymentTargets* = Call_ListDeploymentTargets_593433(
    name: "listDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentTargets",
    validator: validate_ListDeploymentTargets_593434, base: "/",
    url: url_ListDeploymentTargets_593435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_593448 = ref object of OpenApiRestCall_592364
proc url_ListDeployments_593450(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeployments_593449(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593451 = query.getOrDefault("nextToken")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "nextToken", valid_593451
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
  var valid_593452 = header.getOrDefault("X-Amz-Target")
  valid_593452 = validateParameter(valid_593452, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeployments"))
  if valid_593452 != nil:
    section.add "X-Amz-Target", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Signature")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Signature", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Content-Sha256", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Date")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Date", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Credential")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Credential", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Security-Token")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Security-Token", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Algorithm")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Algorithm", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-SignedHeaders", valid_593459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593461: Call_ListDeployments_593448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_593461.validator(path, query, header, formData, body)
  let scheme = call_593461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593461.url(scheme.get, call_593461.host, call_593461.base,
                         call_593461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593461, url, valid)

proc call*(call_593462: Call_ListDeployments_593448; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593463 = newJObject()
  var body_593464 = newJObject()
  add(query_593463, "nextToken", newJString(nextToken))
  if body != nil:
    body_593464 = body
  result = call_593462.call(nil, query_593463, nil, nil, body_593464)

var listDeployments* = Call_ListDeployments_593448(name: "listDeployments",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeployments",
    validator: validate_ListDeployments_593449, base: "/", url: url_ListDeployments_593450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGitHubAccountTokenNames_593465 = ref object of OpenApiRestCall_592364
proc url_ListGitHubAccountTokenNames_593467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGitHubAccountTokenNames_593466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the names of stored connections to GitHub accounts.
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
  var valid_593468 = header.getOrDefault("X-Amz-Target")
  valid_593468 = validateParameter(valid_593468, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListGitHubAccountTokenNames"))
  if valid_593468 != nil:
    section.add "X-Amz-Target", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Signature")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Signature", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Content-Sha256", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Date")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Date", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Credential")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Credential", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Security-Token")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Security-Token", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Algorithm")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Algorithm", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-SignedHeaders", valid_593475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593477: Call_ListGitHubAccountTokenNames_593465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the names of stored connections to GitHub accounts.
  ## 
  let valid = call_593477.validator(path, query, header, formData, body)
  let scheme = call_593477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593477.url(scheme.get, call_593477.host, call_593477.base,
                         call_593477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593477, url, valid)

proc call*(call_593478: Call_ListGitHubAccountTokenNames_593465; body: JsonNode): Recallable =
  ## listGitHubAccountTokenNames
  ## Lists the names of stored connections to GitHub accounts.
  ##   body: JObject (required)
  var body_593479 = newJObject()
  if body != nil:
    body_593479 = body
  result = call_593478.call(nil, nil, nil, nil, body_593479)

var listGitHubAccountTokenNames* = Call_ListGitHubAccountTokenNames_593465(
    name: "listGitHubAccountTokenNames", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListGitHubAccountTokenNames",
    validator: validate_ListGitHubAccountTokenNames_593466, base: "/",
    url: url_ListGitHubAccountTokenNames_593467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOnPremisesInstances_593480 = ref object of OpenApiRestCall_592364
proc url_ListOnPremisesInstances_593482(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOnPremisesInstances_593481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
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
  var valid_593483 = header.getOrDefault("X-Amz-Target")
  valid_593483 = validateParameter(valid_593483, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListOnPremisesInstances"))
  if valid_593483 != nil:
    section.add "X-Amz-Target", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Signature")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Signature", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Content-Sha256", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Date")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Date", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Credential")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Credential", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Security-Token")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Security-Token", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Algorithm")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Algorithm", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-SignedHeaders", valid_593490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_ListOnPremisesInstances_593480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ## 
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_ListOnPremisesInstances_593480; body: JsonNode): Recallable =
  ## listOnPremisesInstances
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ##   body: JObject (required)
  var body_593494 = newJObject()
  if body != nil:
    body_593494 = body
  result = call_593493.call(nil, nil, nil, nil, body_593494)

var listOnPremisesInstances* = Call_ListOnPremisesInstances_593480(
    name: "listOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListOnPremisesInstances",
    validator: validate_ListOnPremisesInstances_593481, base: "/",
    url: url_ListOnPremisesInstances_593482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593495 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593497(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593496(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
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
  var valid_593498 = header.getOrDefault("X-Amz-Target")
  valid_593498 = validateParameter(valid_593498, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListTagsForResource"))
  if valid_593498 != nil:
    section.add "X-Amz-Target", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Signature")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Signature", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Content-Sha256", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Date")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Date", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Credential")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Credential", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Security-Token")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Security-Token", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Algorithm")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Algorithm", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-SignedHeaders", valid_593505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593507: Call_ListTagsForResource_593495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ## 
  let valid = call_593507.validator(path, query, header, formData, body)
  let scheme = call_593507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593507.url(scheme.get, call_593507.host, call_593507.base,
                         call_593507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593507, url, valid)

proc call*(call_593508: Call_ListTagsForResource_593495; body: JsonNode): Recallable =
  ## listTagsForResource
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ##   body: JObject (required)
  var body_593509 = newJObject()
  if body != nil:
    body_593509 = body
  result = call_593508.call(nil, nil, nil, nil, body_593509)

var listTagsForResource* = Call_ListTagsForResource_593495(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListTagsForResource",
    validator: validate_ListTagsForResource_593496, base: "/",
    url: url_ListTagsForResource_593497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleEventHookExecutionStatus_593510 = ref object of OpenApiRestCall_592364
proc url_PutLifecycleEventHookExecutionStatus_593512(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLifecycleEventHookExecutionStatus_593511(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
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
      "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"))
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

proc call*(call_593522: Call_PutLifecycleEventHookExecutionStatus_593510;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ## 
  let valid = call_593522.validator(path, query, header, formData, body)
  let scheme = call_593522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593522.url(scheme.get, call_593522.host, call_593522.base,
                         call_593522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593522, url, valid)

proc call*(call_593523: Call_PutLifecycleEventHookExecutionStatus_593510;
          body: JsonNode): Recallable =
  ## putLifecycleEventHookExecutionStatus
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ##   body: JObject (required)
  var body_593524 = newJObject()
  if body != nil:
    body_593524 = body
  result = call_593523.call(nil, nil, nil, nil, body_593524)

var putLifecycleEventHookExecutionStatus* = Call_PutLifecycleEventHookExecutionStatus_593510(
    name: "putLifecycleEventHookExecutionStatus", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus",
    validator: validate_PutLifecycleEventHookExecutionStatus_593511, base: "/",
    url: url_PutLifecycleEventHookExecutionStatus_593512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterApplicationRevision_593525 = ref object of OpenApiRestCall_592364
proc url_RegisterApplicationRevision_593527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterApplicationRevision_593526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers with AWS CodeDeploy a revision for the specified application.
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
  var valid_593528 = header.getOrDefault("X-Amz-Target")
  valid_593528 = validateParameter(valid_593528, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterApplicationRevision"))
  if valid_593528 != nil:
    section.add "X-Amz-Target", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Signature")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Signature", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Content-Sha256", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Date")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Date", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Credential")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Credential", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Security-Token")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Security-Token", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Algorithm")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Algorithm", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-SignedHeaders", valid_593535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593537: Call_RegisterApplicationRevision_593525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ## 
  let valid = call_593537.validator(path, query, header, formData, body)
  let scheme = call_593537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593537.url(scheme.get, call_593537.host, call_593537.base,
                         call_593537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593537, url, valid)

proc call*(call_593538: Call_RegisterApplicationRevision_593525; body: JsonNode): Recallable =
  ## registerApplicationRevision
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ##   body: JObject (required)
  var body_593539 = newJObject()
  if body != nil:
    body_593539 = body
  result = call_593538.call(nil, nil, nil, nil, body_593539)

var registerApplicationRevision* = Call_RegisterApplicationRevision_593525(
    name: "registerApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterApplicationRevision",
    validator: validate_RegisterApplicationRevision_593526, base: "/",
    url: url_RegisterApplicationRevision_593527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterOnPremisesInstance_593540 = ref object of OpenApiRestCall_592364
proc url_RegisterOnPremisesInstance_593542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterOnPremisesInstance_593541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
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
  var valid_593543 = header.getOrDefault("X-Amz-Target")
  valid_593543 = validateParameter(valid_593543, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterOnPremisesInstance"))
  if valid_593543 != nil:
    section.add "X-Amz-Target", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Signature")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Signature", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Content-Sha256", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Date")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Date", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Credential")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Credential", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Security-Token")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Security-Token", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Algorithm")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Algorithm", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-SignedHeaders", valid_593550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593552: Call_RegisterOnPremisesInstance_593540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ## 
  let valid = call_593552.validator(path, query, header, formData, body)
  let scheme = call_593552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593552.url(scheme.get, call_593552.host, call_593552.base,
                         call_593552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593552, url, valid)

proc call*(call_593553: Call_RegisterOnPremisesInstance_593540; body: JsonNode): Recallable =
  ## registerOnPremisesInstance
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ##   body: JObject (required)
  var body_593554 = newJObject()
  if body != nil:
    body_593554 = body
  result = call_593553.call(nil, nil, nil, nil, body_593554)

var registerOnPremisesInstance* = Call_RegisterOnPremisesInstance_593540(
    name: "registerOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterOnPremisesInstance",
    validator: validate_RegisterOnPremisesInstance_593541, base: "/",
    url: url_RegisterOnPremisesInstance_593542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromOnPremisesInstances_593555 = ref object of OpenApiRestCall_592364
proc url_RemoveTagsFromOnPremisesInstances_593557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromOnPremisesInstances_593556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from one or more on-premises instances.
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
  var valid_593558 = header.getOrDefault("X-Amz-Target")
  valid_593558 = validateParameter(valid_593558, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"))
  if valid_593558 != nil:
    section.add "X-Amz-Target", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Signature")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Signature", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Content-Sha256", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Date")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Date", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Credential")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Credential", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Security-Token")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Security-Token", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Algorithm")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Algorithm", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-SignedHeaders", valid_593565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593567: Call_RemoveTagsFromOnPremisesInstances_593555;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes one or more tags from one or more on-premises instances.
  ## 
  let valid = call_593567.validator(path, query, header, formData, body)
  let scheme = call_593567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593567.url(scheme.get, call_593567.host, call_593567.base,
                         call_593567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593567, url, valid)

proc call*(call_593568: Call_RemoveTagsFromOnPremisesInstances_593555;
          body: JsonNode): Recallable =
  ## removeTagsFromOnPremisesInstances
  ## Removes one or more tags from one or more on-premises instances.
  ##   body: JObject (required)
  var body_593569 = newJObject()
  if body != nil:
    body_593569 = body
  result = call_593568.call(nil, nil, nil, nil, body_593569)

var removeTagsFromOnPremisesInstances* = Call_RemoveTagsFromOnPremisesInstances_593555(
    name: "removeTagsFromOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances",
    validator: validate_RemoveTagsFromOnPremisesInstances_593556, base: "/",
    url: url_RemoveTagsFromOnPremisesInstances_593557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SkipWaitTimeForInstanceTermination_593570 = ref object of OpenApiRestCall_592364
proc url_SkipWaitTimeForInstanceTermination_593572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SkipWaitTimeForInstanceTermination_593571(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
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
  var valid_593573 = header.getOrDefault("X-Amz-Target")
  valid_593573 = validateParameter(valid_593573, JString, required = true, default = newJString(
      "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"))
  if valid_593573 != nil:
    section.add "X-Amz-Target", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Signature")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Signature", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Content-Sha256", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Date")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Date", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Credential")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Credential", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Security-Token")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Security-Token", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Algorithm")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Algorithm", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-SignedHeaders", valid_593580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593582: Call_SkipWaitTimeForInstanceTermination_593570;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ## 
  let valid = call_593582.validator(path, query, header, formData, body)
  let scheme = call_593582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593582.url(scheme.get, call_593582.host, call_593582.base,
                         call_593582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593582, url, valid)

proc call*(call_593583: Call_SkipWaitTimeForInstanceTermination_593570;
          body: JsonNode): Recallable =
  ## skipWaitTimeForInstanceTermination
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ##   body: JObject (required)
  var body_593584 = newJObject()
  if body != nil:
    body_593584 = body
  result = call_593583.call(nil, nil, nil, nil, body_593584)

var skipWaitTimeForInstanceTermination* = Call_SkipWaitTimeForInstanceTermination_593570(
    name: "skipWaitTimeForInstanceTermination", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.SkipWaitTimeForInstanceTermination",
    validator: validate_SkipWaitTimeForInstanceTermination_593571, base: "/",
    url: url_SkipWaitTimeForInstanceTermination_593572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_593585 = ref object of OpenApiRestCall_592364
proc url_StopDeployment_593587(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopDeployment_593586(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Attempts to stop an ongoing deployment.
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
  var valid_593588 = header.getOrDefault("X-Amz-Target")
  valid_593588 = validateParameter(valid_593588, JString, required = true, default = newJString(
      "CodeDeploy_20141006.StopDeployment"))
  if valid_593588 != nil:
    section.add "X-Amz-Target", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Signature")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Signature", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Content-Sha256", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Date")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Date", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Credential")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Credential", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Security-Token")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Security-Token", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Algorithm")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Algorithm", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-SignedHeaders", valid_593595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593597: Call_StopDeployment_593585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop an ongoing deployment.
  ## 
  let valid = call_593597.validator(path, query, header, formData, body)
  let scheme = call_593597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593597.url(scheme.get, call_593597.host, call_593597.base,
                         call_593597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593597, url, valid)

proc call*(call_593598: Call_StopDeployment_593585; body: JsonNode): Recallable =
  ## stopDeployment
  ## Attempts to stop an ongoing deployment.
  ##   body: JObject (required)
  var body_593599 = newJObject()
  if body != nil:
    body_593599 = body
  result = call_593598.call(nil, nil, nil, nil, body_593599)

var stopDeployment* = Call_StopDeployment_593585(name: "stopDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.StopDeployment",
    validator: validate_StopDeployment_593586, base: "/", url: url_StopDeployment_593587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593600 = ref object of OpenApiRestCall_592364
proc url_TagResource_593602(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593601(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
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
  var valid_593603 = header.getOrDefault("X-Amz-Target")
  valid_593603 = validateParameter(valid_593603, JString, required = true, default = newJString(
      "CodeDeploy_20141006.TagResource"))
  if valid_593603 != nil:
    section.add "X-Amz-Target", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Signature")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Signature", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Content-Sha256", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Date")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Date", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Credential")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Credential", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Security-Token")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Security-Token", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Algorithm")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Algorithm", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-SignedHeaders", valid_593610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593612: Call_TagResource_593600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ## 
  let valid = call_593612.validator(path, query, header, formData, body)
  let scheme = call_593612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593612.url(scheme.get, call_593612.host, call_593612.base,
                         call_593612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593612, url, valid)

proc call*(call_593613: Call_TagResource_593600; body: JsonNode): Recallable =
  ## tagResource
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ##   body: JObject (required)
  var body_593614 = newJObject()
  if body != nil:
    body_593614 = body
  result = call_593613.call(nil, nil, nil, nil, body_593614)

var tagResource* = Call_TagResource_593600(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.TagResource",
                                        validator: validate_TagResource_593601,
                                        base: "/", url: url_TagResource_593602,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593615 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593617(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593616(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
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
  var valid_593618 = header.getOrDefault("X-Amz-Target")
  valid_593618 = validateParameter(valid_593618, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UntagResource"))
  if valid_593618 != nil:
    section.add "X-Amz-Target", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Signature")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Signature", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Content-Sha256", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Date")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Date", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Credential")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Credential", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Security-Token")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Security-Token", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Algorithm")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Algorithm", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-SignedHeaders", valid_593625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593627: Call_UntagResource_593615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ## 
  let valid = call_593627.validator(path, query, header, formData, body)
  let scheme = call_593627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593627.url(scheme.get, call_593627.host, call_593627.base,
                         call_593627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593627, url, valid)

proc call*(call_593628: Call_UntagResource_593615; body: JsonNode): Recallable =
  ## untagResource
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ##   body: JObject (required)
  var body_593629 = newJObject()
  if body != nil:
    body_593629 = body
  result = call_593628.call(nil, nil, nil, nil, body_593629)

var untagResource* = Call_UntagResource_593615(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UntagResource",
    validator: validate_UntagResource_593616, base: "/", url: url_UntagResource_593617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_593630 = ref object of OpenApiRestCall_592364
proc url_UpdateApplication_593632(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateApplication_593631(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Changes the name of an application.
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
  var valid_593633 = header.getOrDefault("X-Amz-Target")
  valid_593633 = validateParameter(valid_593633, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateApplication"))
  if valid_593633 != nil:
    section.add "X-Amz-Target", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Signature")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Signature", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Content-Sha256", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Date")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Date", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Credential")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Credential", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Security-Token")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Security-Token", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Algorithm")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Algorithm", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-SignedHeaders", valid_593640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593642: Call_UpdateApplication_593630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the name of an application.
  ## 
  let valid = call_593642.validator(path, query, header, formData, body)
  let scheme = call_593642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593642.url(scheme.get, call_593642.host, call_593642.base,
                         call_593642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593642, url, valid)

proc call*(call_593643: Call_UpdateApplication_593630; body: JsonNode): Recallable =
  ## updateApplication
  ## Changes the name of an application.
  ##   body: JObject (required)
  var body_593644 = newJObject()
  if body != nil:
    body_593644 = body
  result = call_593643.call(nil, nil, nil, nil, body_593644)

var updateApplication* = Call_UpdateApplication_593630(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateApplication",
    validator: validate_UpdateApplication_593631, base: "/",
    url: url_UpdateApplication_593632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentGroup_593645 = ref object of OpenApiRestCall_592364
proc url_UpdateDeploymentGroup_593647(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDeploymentGroup_593646(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about a deployment group.
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
  var valid_593648 = header.getOrDefault("X-Amz-Target")
  valid_593648 = validateParameter(valid_593648, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateDeploymentGroup"))
  if valid_593648 != nil:
    section.add "X-Amz-Target", valid_593648
  var valid_593649 = header.getOrDefault("X-Amz-Signature")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Signature", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Content-Sha256", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Date")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Date", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Credential")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Credential", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Security-Token")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Security-Token", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Algorithm")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Algorithm", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-SignedHeaders", valid_593655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593657: Call_UpdateDeploymentGroup_593645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a deployment group.
  ## 
  let valid = call_593657.validator(path, query, header, formData, body)
  let scheme = call_593657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593657.url(scheme.get, call_593657.host, call_593657.base,
                         call_593657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593657, url, valid)

proc call*(call_593658: Call_UpdateDeploymentGroup_593645; body: JsonNode): Recallable =
  ## updateDeploymentGroup
  ## Changes information about a deployment group.
  ##   body: JObject (required)
  var body_593659 = newJObject()
  if body != nil:
    body_593659 = body
  result = call_593658.call(nil, nil, nil, nil, body_593659)

var updateDeploymentGroup* = Call_UpdateDeploymentGroup_593645(
    name: "updateDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateDeploymentGroup",
    validator: validate_UpdateDeploymentGroup_593646, base: "/",
    url: url_UpdateDeploymentGroup_593647, schemes: {Scheme.Https, Scheme.Http})
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
