
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToOnPremisesInstances_599705 = ref object of OpenApiRestCall_599368
proc url_AddTagsToOnPremisesInstances_599707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToOnPremisesInstances_599706(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "CodeDeploy_20141006.AddTagsToOnPremisesInstances"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AddTagsToOnPremisesInstances_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to on-premises instances.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AddTagsToOnPremisesInstances_599705; body: JsonNode): Recallable =
  ## addTagsToOnPremisesInstances
  ## Adds tags to on-premises instances.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var addTagsToOnPremisesInstances* = Call_AddTagsToOnPremisesInstances_599705(
    name: "addTagsToOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.AddTagsToOnPremisesInstances",
    validator: validate_AddTagsToOnPremisesInstances_599706, base: "/",
    url: url_AddTagsToOnPremisesInstances_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplicationRevisions_599974 = ref object of OpenApiRestCall_599368
proc url_BatchGetApplicationRevisions_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetApplicationRevisions_599975(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplicationRevisions"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_BatchGetApplicationRevisions_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_BatchGetApplicationRevisions_599974; body: JsonNode): Recallable =
  ## batchGetApplicationRevisions
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var batchGetApplicationRevisions* = Call_BatchGetApplicationRevisions_599974(
    name: "batchGetApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplicationRevisions",
    validator: validate_BatchGetApplicationRevisions_599975, base: "/",
    url: url_BatchGetApplicationRevisions_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplications_599989 = ref object of OpenApiRestCall_599368
proc url_BatchGetApplications_599991(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetApplications_599990(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplications"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_BatchGetApplications_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_BatchGetApplications_599989; body: JsonNode): Recallable =
  ## batchGetApplications
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var batchGetApplications* = Call_BatchGetApplications_599989(
    name: "batchGetApplications", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplications",
    validator: validate_BatchGetApplications_599990, base: "/",
    url: url_BatchGetApplications_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentGroups_600004 = ref object of OpenApiRestCall_599368
proc url_BatchGetDeploymentGroups_600006(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentGroups_600005(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentGroups"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_BatchGetDeploymentGroups_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployment groups.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_BatchGetDeploymentGroups_600004; body: JsonNode): Recallable =
  ## batchGetDeploymentGroups
  ## Gets information about one or more deployment groups.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var batchGetDeploymentGroups* = Call_BatchGetDeploymentGroups_600004(
    name: "batchGetDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentGroups",
    validator: validate_BatchGetDeploymentGroups_600005, base: "/",
    url: url_BatchGetDeploymentGroups_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentInstances_600019 = ref object of OpenApiRestCall_599368
proc url_BatchGetDeploymentInstances_600021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentInstances_600020(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentInstances"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_BatchGetDeploymentInstances_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_BatchGetDeploymentInstances_600019; body: JsonNode): Recallable =
  ## batchGetDeploymentInstances
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var batchGetDeploymentInstances* = Call_BatchGetDeploymentInstances_600019(
    name: "batchGetDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentInstances",
    validator: validate_BatchGetDeploymentInstances_600020, base: "/",
    url: url_BatchGetDeploymentInstances_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentTargets_600034 = ref object of OpenApiRestCall_599368
proc url_BatchGetDeploymentTargets_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentTargets_600035(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentTargets"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_BatchGetDeploymentTargets_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_BatchGetDeploymentTargets_600034; body: JsonNode): Recallable =
  ## batchGetDeploymentTargets
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var batchGetDeploymentTargets* = Call_BatchGetDeploymentTargets_600034(
    name: "batchGetDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentTargets",
    validator: validate_BatchGetDeploymentTargets_600035, base: "/",
    url: url_BatchGetDeploymentTargets_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeployments_600049 = ref object of OpenApiRestCall_599368
proc url_BatchGetDeployments_600051(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeployments_600050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeployments"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_BatchGetDeployments_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_BatchGetDeployments_600049; body: JsonNode): Recallable =
  ## batchGetDeployments
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var batchGetDeployments* = Call_BatchGetDeployments_600049(
    name: "batchGetDeployments", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeployments",
    validator: validate_BatchGetDeployments_600050, base: "/",
    url: url_BatchGetDeployments_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetOnPremisesInstances_600064 = ref object of OpenApiRestCall_599368
proc url_BatchGetOnPremisesInstances_600066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetOnPremisesInstances_600065(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetOnPremisesInstances"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_BatchGetOnPremisesInstances_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_BatchGetOnPremisesInstances_600064; body: JsonNode): Recallable =
  ## batchGetOnPremisesInstances
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var batchGetOnPremisesInstances* = Call_BatchGetOnPremisesInstances_600064(
    name: "batchGetOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetOnPremisesInstances",
    validator: validate_BatchGetOnPremisesInstances_600065, base: "/",
    url: url_BatchGetOnPremisesInstances_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ContinueDeployment_600079 = ref object of OpenApiRestCall_599368
proc url_ContinueDeployment_600081(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ContinueDeployment_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ContinueDeployment"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_ContinueDeployment_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_ContinueDeployment_600079; body: JsonNode): Recallable =
  ## continueDeployment
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var continueDeployment* = Call_ContinueDeployment_600079(
    name: "continueDeployment", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ContinueDeployment",
    validator: validate_ContinueDeployment_600080, base: "/",
    url: url_ContinueDeployment_600081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_600094 = ref object of OpenApiRestCall_599368
proc url_CreateApplication_600096(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_600095(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateApplication"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_CreateApplication_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_CreateApplication_600094; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var createApplication* = Call_CreateApplication_600094(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateApplication",
    validator: validate_CreateApplication_600095, base: "/",
    url: url_CreateApplication_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_600109 = ref object of OpenApiRestCall_599368
proc url_CreateDeployment_600111(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeployment_600110(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeployment"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_CreateDeployment_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys an application revision through the specified deployment group.
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_CreateDeployment_600109; body: JsonNode): Recallable =
  ## createDeployment
  ## Deploys an application revision through the specified deployment group.
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var createDeployment* = Call_CreateDeployment_600109(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeployment",
    validator: validate_CreateDeployment_600110, base: "/",
    url: url_CreateDeployment_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentConfig_600124 = ref object of OpenApiRestCall_599368
proc url_CreateDeploymentConfig_600126(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentConfig_600125(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentConfig"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_CreateDeploymentConfig_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a deployment configuration. 
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_CreateDeploymentConfig_600124; body: JsonNode): Recallable =
  ## createDeploymentConfig
  ##  Creates a deployment configuration. 
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var createDeploymentConfig* = Call_CreateDeploymentConfig_600124(
    name: "createDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentConfig",
    validator: validate_CreateDeploymentConfig_600125, base: "/",
    url: url_CreateDeploymentConfig_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentGroup_600139 = ref object of OpenApiRestCall_599368
proc url_CreateDeploymentGroup_600141(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentGroup_600140(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentGroup"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateDeploymentGroup_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment group to which application revisions are deployed.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateDeploymentGroup_600139; body: JsonNode): Recallable =
  ## createDeploymentGroup
  ## Creates a deployment group to which application revisions are deployed.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var createDeploymentGroup* = Call_CreateDeploymentGroup_600139(
    name: "createDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentGroup",
    validator: validate_CreateDeploymentGroup_600140, base: "/",
    url: url_CreateDeploymentGroup_600141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteApplication_600156(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplication_600155(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteApplication"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DeleteApplication_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DeleteApplication_600154; body: JsonNode): Recallable =
  ## deleteApplication
  ## Deletes an application.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var deleteApplication* = Call_DeleteApplication_600154(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteApplication",
    validator: validate_DeleteApplication_600155, base: "/",
    url: url_DeleteApplication_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentConfig_600169 = ref object of OpenApiRestCall_599368
proc url_DeleteDeploymentConfig_600171(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeploymentConfig_600170(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentConfig"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DeleteDeploymentConfig_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DeleteDeploymentConfig_600169; body: JsonNode): Recallable =
  ## deleteDeploymentConfig
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var deleteDeploymentConfig* = Call_DeleteDeploymentConfig_600169(
    name: "deleteDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentConfig",
    validator: validate_DeleteDeploymentConfig_600170, base: "/",
    url: url_DeleteDeploymentConfig_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentGroup_600184 = ref object of OpenApiRestCall_599368
proc url_DeleteDeploymentGroup_600186(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeploymentGroup_600185(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentGroup"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_DeleteDeploymentGroup_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a deployment group.
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_DeleteDeploymentGroup_600184; body: JsonNode): Recallable =
  ## deleteDeploymentGroup
  ## Deletes a deployment group.
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var deleteDeploymentGroup* = Call_DeleteDeploymentGroup_600184(
    name: "deleteDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentGroup",
    validator: validate_DeleteDeploymentGroup_600185, base: "/",
    url: url_DeleteDeploymentGroup_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGitHubAccountToken_600199 = ref object of OpenApiRestCall_599368
proc url_DeleteGitHubAccountToken_600201(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGitHubAccountToken_600200(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteGitHubAccountToken"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_DeleteGitHubAccountToken_600199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a GitHub account connection.
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_DeleteGitHubAccountToken_600199; body: JsonNode): Recallable =
  ## deleteGitHubAccountToken
  ## Deletes a GitHub account connection.
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var deleteGitHubAccountToken* = Call_DeleteGitHubAccountToken_600199(
    name: "deleteGitHubAccountToken", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteGitHubAccountToken",
    validator: validate_DeleteGitHubAccountToken_600200, base: "/",
    url: url_DeleteGitHubAccountToken_600201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterOnPremisesInstance_600214 = ref object of OpenApiRestCall_599368
proc url_DeregisterOnPremisesInstance_600216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterOnPremisesInstance_600215(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeregisterOnPremisesInstance"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_DeregisterOnPremisesInstance_600214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an on-premises instance.
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_DeregisterOnPremisesInstance_600214; body: JsonNode): Recallable =
  ## deregisterOnPremisesInstance
  ## Deregisters an on-premises instance.
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var deregisterOnPremisesInstance* = Call_DeregisterOnPremisesInstance_600214(
    name: "deregisterOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeregisterOnPremisesInstance",
    validator: validate_DeregisterOnPremisesInstance_600215, base: "/",
    url: url_DeregisterOnPremisesInstance_600216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_600229 = ref object of OpenApiRestCall_599368
proc url_GetApplication_600231(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplication_600230(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplication"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_GetApplication_600229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application.
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_GetApplication_600229; body: JsonNode): Recallable =
  ## getApplication
  ## Gets information about an application.
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var getApplication* = Call_GetApplication_600229(name: "getApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplication",
    validator: validate_GetApplication_600230, base: "/", url: url_GetApplication_600231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationRevision_600244 = ref object of OpenApiRestCall_599368
proc url_GetApplicationRevision_600246(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplicationRevision_600245(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplicationRevision"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_GetApplicationRevision_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application revision.
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_GetApplicationRevision_600244; body: JsonNode): Recallable =
  ## getApplicationRevision
  ## Gets information about an application revision.
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var getApplicationRevision* = Call_GetApplicationRevision_600244(
    name: "getApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplicationRevision",
    validator: validate_GetApplicationRevision_600245, base: "/",
    url: url_GetApplicationRevision_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_600259 = ref object of OpenApiRestCall_599368
proc url_GetDeployment_600261(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeployment_600260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeployment"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_GetDeployment_600259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_GetDeployment_600259; body: JsonNode): Recallable =
  ## getDeployment
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var getDeployment* = Call_GetDeployment_600259(name: "getDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeployment",
    validator: validate_GetDeployment_600260, base: "/", url: url_GetDeployment_600261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentConfig_600274 = ref object of OpenApiRestCall_599368
proc url_GetDeploymentConfig_600276(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentConfig_600275(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentConfig"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_GetDeploymentConfig_600274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment configuration.
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_GetDeploymentConfig_600274; body: JsonNode): Recallable =
  ## getDeploymentConfig
  ## Gets information about a deployment configuration.
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var getDeploymentConfig* = Call_GetDeploymentConfig_600274(
    name: "getDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentConfig",
    validator: validate_GetDeploymentConfig_600275, base: "/",
    url: url_GetDeploymentConfig_600276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentGroup_600289 = ref object of OpenApiRestCall_599368
proc url_GetDeploymentGroup_600291(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentGroup_600290(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentGroup"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_GetDeploymentGroup_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment group.
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_GetDeploymentGroup_600289; body: JsonNode): Recallable =
  ## getDeploymentGroup
  ## Gets information about a deployment group.
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var getDeploymentGroup* = Call_GetDeploymentGroup_600289(
    name: "getDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentGroup",
    validator: validate_GetDeploymentGroup_600290, base: "/",
    url: url_GetDeploymentGroup_600291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentInstance_600304 = ref object of OpenApiRestCall_599368
proc url_GetDeploymentInstance_600306(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentInstance_600305(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600309 = header.getOrDefault("X-Amz-Target")
  valid_600309 = validateParameter(valid_600309, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentInstance"))
  if valid_600309 != nil:
    section.add "X-Amz-Target", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_GetDeploymentInstance_600304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an instance as part of a deployment.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_GetDeploymentInstance_600304; body: JsonNode): Recallable =
  ## getDeploymentInstance
  ## Gets information about an instance as part of a deployment.
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var getDeploymentInstance* = Call_GetDeploymentInstance_600304(
    name: "getDeploymentInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentInstance",
    validator: validate_GetDeploymentInstance_600305, base: "/",
    url: url_GetDeploymentInstance_600306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentTarget_600319 = ref object of OpenApiRestCall_599368
proc url_GetDeploymentTarget_600321(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentTarget_600320(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentTarget"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_GetDeploymentTarget_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about a deployment target. 
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_GetDeploymentTarget_600319; body: JsonNode): Recallable =
  ## getDeploymentTarget
  ##  Returns information about a deployment target. 
  ##   body: JObject (required)
  var body_600333 = newJObject()
  if body != nil:
    body_600333 = body
  result = call_600332.call(nil, nil, nil, nil, body_600333)

var getDeploymentTarget* = Call_GetDeploymentTarget_600319(
    name: "getDeploymentTarget", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentTarget",
    validator: validate_GetDeploymentTarget_600320, base: "/",
    url: url_GetDeploymentTarget_600321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOnPremisesInstance_600334 = ref object of OpenApiRestCall_599368
proc url_GetOnPremisesInstance_600336(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOnPremisesInstance_600335(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600339 = header.getOrDefault("X-Amz-Target")
  valid_600339 = validateParameter(valid_600339, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetOnPremisesInstance"))
  if valid_600339 != nil:
    section.add "X-Amz-Target", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_GetOnPremisesInstance_600334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets information about an on-premises instance. 
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_GetOnPremisesInstance_600334; body: JsonNode): Recallable =
  ## getOnPremisesInstance
  ##  Gets information about an on-premises instance. 
  ##   body: JObject (required)
  var body_600348 = newJObject()
  if body != nil:
    body_600348 = body
  result = call_600347.call(nil, nil, nil, nil, body_600348)

var getOnPremisesInstance* = Call_GetOnPremisesInstance_600334(
    name: "getOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetOnPremisesInstance",
    validator: validate_GetOnPremisesInstance_600335, base: "/",
    url: url_GetOnPremisesInstance_600336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationRevisions_600349 = ref object of OpenApiRestCall_599368
proc url_ListApplicationRevisions_600351(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplicationRevisions_600350(path: JsonNode; query: JsonNode;
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
  var valid_600352 = query.getOrDefault("nextToken")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "nextToken", valid_600352
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
  var valid_600353 = header.getOrDefault("X-Amz-Date")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Date", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Security-Token")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Security-Token", valid_600354
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600355 = header.getOrDefault("X-Amz-Target")
  valid_600355 = validateParameter(valid_600355, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplicationRevisions"))
  if valid_600355 != nil:
    section.add "X-Amz-Target", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Content-Sha256", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Algorithm")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Algorithm", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Signature")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Signature", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-SignedHeaders", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Credential")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Credential", valid_600360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600362: Call_ListApplicationRevisions_600349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about revisions for an application.
  ## 
  let valid = call_600362.validator(path, query, header, formData, body)
  let scheme = call_600362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600362.url(scheme.get, call_600362.host, call_600362.base,
                         call_600362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600362, url, valid)

proc call*(call_600363: Call_ListApplicationRevisions_600349; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplicationRevisions
  ## Lists information about revisions for an application.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600364 = newJObject()
  var body_600365 = newJObject()
  add(query_600364, "nextToken", newJString(nextToken))
  if body != nil:
    body_600365 = body
  result = call_600363.call(nil, query_600364, nil, nil, body_600365)

var listApplicationRevisions* = Call_ListApplicationRevisions_600349(
    name: "listApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplicationRevisions",
    validator: validate_ListApplicationRevisions_600350, base: "/",
    url: url_ListApplicationRevisions_600351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_600367 = ref object of OpenApiRestCall_599368
proc url_ListApplications_600369(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_600368(path: JsonNode; query: JsonNode;
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
  var valid_600370 = query.getOrDefault("nextToken")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "nextToken", valid_600370
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
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600373 = header.getOrDefault("X-Amz-Target")
  valid_600373 = validateParameter(valid_600373, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplications"))
  if valid_600373 != nil:
    section.add "X-Amz-Target", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600380: Call_ListApplications_600367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_ListApplications_600367; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the applications registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600382 = newJObject()
  var body_600383 = newJObject()
  add(query_600382, "nextToken", newJString(nextToken))
  if body != nil:
    body_600383 = body
  result = call_600381.call(nil, query_600382, nil, nil, body_600383)

var listApplications* = Call_ListApplications_600367(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplications",
    validator: validate_ListApplications_600368, base: "/",
    url: url_ListApplications_600369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentConfigs_600384 = ref object of OpenApiRestCall_599368
proc url_ListDeploymentConfigs_600386(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentConfigs_600385(path: JsonNode; query: JsonNode;
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
  var valid_600387 = query.getOrDefault("nextToken")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "nextToken", valid_600387
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
  var valid_600388 = header.getOrDefault("X-Amz-Date")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Date", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Security-Token")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Security-Token", valid_600389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600390 = header.getOrDefault("X-Amz-Target")
  valid_600390 = validateParameter(valid_600390, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentConfigs"))
  if valid_600390 != nil:
    section.add "X-Amz-Target", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Content-Sha256", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Algorithm")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Algorithm", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Signature")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Signature", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-SignedHeaders", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Credential")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Credential", valid_600395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600397: Call_ListDeploymentConfigs_600384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  let valid = call_600397.validator(path, query, header, formData, body)
  let scheme = call_600397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600397.url(scheme.get, call_600397.host, call_600397.base,
                         call_600397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600397, url, valid)

proc call*(call_600398: Call_ListDeploymentConfigs_600384; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentConfigs
  ## Lists the deployment configurations with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600399 = newJObject()
  var body_600400 = newJObject()
  add(query_600399, "nextToken", newJString(nextToken))
  if body != nil:
    body_600400 = body
  result = call_600398.call(nil, query_600399, nil, nil, body_600400)

var listDeploymentConfigs* = Call_ListDeploymentConfigs_600384(
    name: "listDeploymentConfigs", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentConfigs",
    validator: validate_ListDeploymentConfigs_600385, base: "/",
    url: url_ListDeploymentConfigs_600386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentGroups_600401 = ref object of OpenApiRestCall_599368
proc url_ListDeploymentGroups_600403(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentGroups_600402(path: JsonNode; query: JsonNode;
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
  var valid_600404 = query.getOrDefault("nextToken")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "nextToken", valid_600404
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
  var valid_600405 = header.getOrDefault("X-Amz-Date")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Date", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Security-Token")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Security-Token", valid_600406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600407 = header.getOrDefault("X-Amz-Target")
  valid_600407 = validateParameter(valid_600407, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentGroups"))
  if valid_600407 != nil:
    section.add "X-Amz-Target", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Content-Sha256", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Algorithm")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Algorithm", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-Signature")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Signature", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-SignedHeaders", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Credential")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Credential", valid_600412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600414: Call_ListDeploymentGroups_600401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_600414.validator(path, query, header, formData, body)
  let scheme = call_600414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600414.url(scheme.get, call_600414.host, call_600414.base,
                         call_600414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600414, url, valid)

proc call*(call_600415: Call_ListDeploymentGroups_600401; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentGroups
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600416 = newJObject()
  var body_600417 = newJObject()
  add(query_600416, "nextToken", newJString(nextToken))
  if body != nil:
    body_600417 = body
  result = call_600415.call(nil, query_600416, nil, nil, body_600417)

var listDeploymentGroups* = Call_ListDeploymentGroups_600401(
    name: "listDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentGroups",
    validator: validate_ListDeploymentGroups_600402, base: "/",
    url: url_ListDeploymentGroups_600403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentInstances_600418 = ref object of OpenApiRestCall_599368
proc url_ListDeploymentInstances_600420(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentInstances_600419(path: JsonNode; query: JsonNode;
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
  var valid_600421 = query.getOrDefault("nextToken")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "nextToken", valid_600421
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
  var valid_600422 = header.getOrDefault("X-Amz-Date")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Date", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Security-Token")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Security-Token", valid_600423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600424 = header.getOrDefault("X-Amz-Target")
  valid_600424 = validateParameter(valid_600424, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentInstances"))
  if valid_600424 != nil:
    section.add "X-Amz-Target", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Content-Sha256", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Algorithm")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Algorithm", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Signature")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Signature", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-SignedHeaders", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Credential")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Credential", valid_600429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600431: Call_ListDeploymentInstances_600418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  let valid = call_600431.validator(path, query, header, formData, body)
  let scheme = call_600431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600431.url(scheme.get, call_600431.host, call_600431.base,
                         call_600431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600431, url, valid)

proc call*(call_600432: Call_ListDeploymentInstances_600418; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentInstances
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600433 = newJObject()
  var body_600434 = newJObject()
  add(query_600433, "nextToken", newJString(nextToken))
  if body != nil:
    body_600434 = body
  result = call_600432.call(nil, query_600433, nil, nil, body_600434)

var listDeploymentInstances* = Call_ListDeploymentInstances_600418(
    name: "listDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentInstances",
    validator: validate_ListDeploymentInstances_600419, base: "/",
    url: url_ListDeploymentInstances_600420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentTargets_600435 = ref object of OpenApiRestCall_599368
proc url_ListDeploymentTargets_600437(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentTargets_600436(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600438 = header.getOrDefault("X-Amz-Date")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Date", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Security-Token")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Security-Token", valid_600439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600440 = header.getOrDefault("X-Amz-Target")
  valid_600440 = validateParameter(valid_600440, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentTargets"))
  if valid_600440 != nil:
    section.add "X-Amz-Target", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Content-Sha256", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Algorithm")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Algorithm", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Signature")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Signature", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-SignedHeaders", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Credential")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Credential", valid_600445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600447: Call_ListDeploymentTargets_600435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of target IDs that are associated a deployment. 
  ## 
  let valid = call_600447.validator(path, query, header, formData, body)
  let scheme = call_600447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600447.url(scheme.get, call_600447.host, call_600447.base,
                         call_600447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600447, url, valid)

proc call*(call_600448: Call_ListDeploymentTargets_600435; body: JsonNode): Recallable =
  ## listDeploymentTargets
  ##  Returns an array of target IDs that are associated a deployment. 
  ##   body: JObject (required)
  var body_600449 = newJObject()
  if body != nil:
    body_600449 = body
  result = call_600448.call(nil, nil, nil, nil, body_600449)

var listDeploymentTargets* = Call_ListDeploymentTargets_600435(
    name: "listDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentTargets",
    validator: validate_ListDeploymentTargets_600436, base: "/",
    url: url_ListDeploymentTargets_600437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_600450 = ref object of OpenApiRestCall_599368
proc url_ListDeployments_600452(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeployments_600451(path: JsonNode; query: JsonNode;
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
  var valid_600453 = query.getOrDefault("nextToken")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "nextToken", valid_600453
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
  var valid_600454 = header.getOrDefault("X-Amz-Date")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Date", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Security-Token")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Security-Token", valid_600455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600456 = header.getOrDefault("X-Amz-Target")
  valid_600456 = validateParameter(valid_600456, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeployments"))
  if valid_600456 != nil:
    section.add "X-Amz-Target", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Content-Sha256", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Algorithm")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Algorithm", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Signature")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Signature", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-SignedHeaders", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Credential")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Credential", valid_600461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600463: Call_ListDeployments_600450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_600463.validator(path, query, header, formData, body)
  let scheme = call_600463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600463.url(scheme.get, call_600463.host, call_600463.base,
                         call_600463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600463, url, valid)

proc call*(call_600464: Call_ListDeployments_600450; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600465 = newJObject()
  var body_600466 = newJObject()
  add(query_600465, "nextToken", newJString(nextToken))
  if body != nil:
    body_600466 = body
  result = call_600464.call(nil, query_600465, nil, nil, body_600466)

var listDeployments* = Call_ListDeployments_600450(name: "listDeployments",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeployments",
    validator: validate_ListDeployments_600451, base: "/", url: url_ListDeployments_600452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGitHubAccountTokenNames_600467 = ref object of OpenApiRestCall_599368
proc url_ListGitHubAccountTokenNames_600469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGitHubAccountTokenNames_600468(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600470 = header.getOrDefault("X-Amz-Date")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Date", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Security-Token")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Security-Token", valid_600471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600472 = header.getOrDefault("X-Amz-Target")
  valid_600472 = validateParameter(valid_600472, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListGitHubAccountTokenNames"))
  if valid_600472 != nil:
    section.add "X-Amz-Target", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Content-Sha256", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Algorithm")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Algorithm", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Signature")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Signature", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-SignedHeaders", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Credential")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Credential", valid_600477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600479: Call_ListGitHubAccountTokenNames_600467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the names of stored connections to GitHub accounts.
  ## 
  let valid = call_600479.validator(path, query, header, formData, body)
  let scheme = call_600479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600479.url(scheme.get, call_600479.host, call_600479.base,
                         call_600479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600479, url, valid)

proc call*(call_600480: Call_ListGitHubAccountTokenNames_600467; body: JsonNode): Recallable =
  ## listGitHubAccountTokenNames
  ## Lists the names of stored connections to GitHub accounts.
  ##   body: JObject (required)
  var body_600481 = newJObject()
  if body != nil:
    body_600481 = body
  result = call_600480.call(nil, nil, nil, nil, body_600481)

var listGitHubAccountTokenNames* = Call_ListGitHubAccountTokenNames_600467(
    name: "listGitHubAccountTokenNames", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListGitHubAccountTokenNames",
    validator: validate_ListGitHubAccountTokenNames_600468, base: "/",
    url: url_ListGitHubAccountTokenNames_600469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOnPremisesInstances_600482 = ref object of OpenApiRestCall_599368
proc url_ListOnPremisesInstances_600484(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOnPremisesInstances_600483(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600485 = header.getOrDefault("X-Amz-Date")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Date", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Security-Token")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Security-Token", valid_600486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600487 = header.getOrDefault("X-Amz-Target")
  valid_600487 = validateParameter(valid_600487, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListOnPremisesInstances"))
  if valid_600487 != nil:
    section.add "X-Amz-Target", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Content-Sha256", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Algorithm")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Algorithm", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Signature")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Signature", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-SignedHeaders", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Credential")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Credential", valid_600492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600494: Call_ListOnPremisesInstances_600482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ## 
  let valid = call_600494.validator(path, query, header, formData, body)
  let scheme = call_600494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600494.url(scheme.get, call_600494.host, call_600494.base,
                         call_600494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600494, url, valid)

proc call*(call_600495: Call_ListOnPremisesInstances_600482; body: JsonNode): Recallable =
  ## listOnPremisesInstances
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ##   body: JObject (required)
  var body_600496 = newJObject()
  if body != nil:
    body_600496 = body
  result = call_600495.call(nil, nil, nil, nil, body_600496)

var listOnPremisesInstances* = Call_ListOnPremisesInstances_600482(
    name: "listOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListOnPremisesInstances",
    validator: validate_ListOnPremisesInstances_600483, base: "/",
    url: url_ListOnPremisesInstances_600484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600497 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600499(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600498(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600500 = header.getOrDefault("X-Amz-Date")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Date", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Security-Token")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Security-Token", valid_600501
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600502 = header.getOrDefault("X-Amz-Target")
  valid_600502 = validateParameter(valid_600502, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListTagsForResource"))
  if valid_600502 != nil:
    section.add "X-Amz-Target", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Content-Sha256", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Algorithm")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Algorithm", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Signature")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Signature", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-SignedHeaders", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Credential")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Credential", valid_600507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600509: Call_ListTagsForResource_600497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ## 
  let valid = call_600509.validator(path, query, header, formData, body)
  let scheme = call_600509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600509.url(scheme.get, call_600509.host, call_600509.base,
                         call_600509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600509, url, valid)

proc call*(call_600510: Call_ListTagsForResource_600497; body: JsonNode): Recallable =
  ## listTagsForResource
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ##   body: JObject (required)
  var body_600511 = newJObject()
  if body != nil:
    body_600511 = body
  result = call_600510.call(nil, nil, nil, nil, body_600511)

var listTagsForResource* = Call_ListTagsForResource_600497(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListTagsForResource",
    validator: validate_ListTagsForResource_600498, base: "/",
    url: url_ListTagsForResource_600499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleEventHookExecutionStatus_600512 = ref object of OpenApiRestCall_599368
proc url_PutLifecycleEventHookExecutionStatus_600514(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLifecycleEventHookExecutionStatus_600513(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600515 = header.getOrDefault("X-Amz-Date")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Date", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Security-Token")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Security-Token", valid_600516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600517 = header.getOrDefault("X-Amz-Target")
  valid_600517 = validateParameter(valid_600517, JString, required = true, default = newJString(
      "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"))
  if valid_600517 != nil:
    section.add "X-Amz-Target", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Content-Sha256", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Algorithm")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Algorithm", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Signature")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Signature", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-SignedHeaders", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Credential")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Credential", valid_600522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600524: Call_PutLifecycleEventHookExecutionStatus_600512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ## 
  let valid = call_600524.validator(path, query, header, formData, body)
  let scheme = call_600524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600524.url(scheme.get, call_600524.host, call_600524.base,
                         call_600524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600524, url, valid)

proc call*(call_600525: Call_PutLifecycleEventHookExecutionStatus_600512;
          body: JsonNode): Recallable =
  ## putLifecycleEventHookExecutionStatus
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ##   body: JObject (required)
  var body_600526 = newJObject()
  if body != nil:
    body_600526 = body
  result = call_600525.call(nil, nil, nil, nil, body_600526)

var putLifecycleEventHookExecutionStatus* = Call_PutLifecycleEventHookExecutionStatus_600512(
    name: "putLifecycleEventHookExecutionStatus", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus",
    validator: validate_PutLifecycleEventHookExecutionStatus_600513, base: "/",
    url: url_PutLifecycleEventHookExecutionStatus_600514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterApplicationRevision_600527 = ref object of OpenApiRestCall_599368
proc url_RegisterApplicationRevision_600529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterApplicationRevision_600528(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600530 = header.getOrDefault("X-Amz-Date")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Date", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Security-Token")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Security-Token", valid_600531
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600532 = header.getOrDefault("X-Amz-Target")
  valid_600532 = validateParameter(valid_600532, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterApplicationRevision"))
  if valid_600532 != nil:
    section.add "X-Amz-Target", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Content-Sha256", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Algorithm")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Algorithm", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Signature")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Signature", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-SignedHeaders", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Credential")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Credential", valid_600537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600539: Call_RegisterApplicationRevision_600527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ## 
  let valid = call_600539.validator(path, query, header, formData, body)
  let scheme = call_600539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600539.url(scheme.get, call_600539.host, call_600539.base,
                         call_600539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600539, url, valid)

proc call*(call_600540: Call_RegisterApplicationRevision_600527; body: JsonNode): Recallable =
  ## registerApplicationRevision
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ##   body: JObject (required)
  var body_600541 = newJObject()
  if body != nil:
    body_600541 = body
  result = call_600540.call(nil, nil, nil, nil, body_600541)

var registerApplicationRevision* = Call_RegisterApplicationRevision_600527(
    name: "registerApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterApplicationRevision",
    validator: validate_RegisterApplicationRevision_600528, base: "/",
    url: url_RegisterApplicationRevision_600529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterOnPremisesInstance_600542 = ref object of OpenApiRestCall_599368
proc url_RegisterOnPremisesInstance_600544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterOnPremisesInstance_600543(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600545 = header.getOrDefault("X-Amz-Date")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Date", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Security-Token")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Security-Token", valid_600546
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600547 = header.getOrDefault("X-Amz-Target")
  valid_600547 = validateParameter(valid_600547, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterOnPremisesInstance"))
  if valid_600547 != nil:
    section.add "X-Amz-Target", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Content-Sha256", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Algorithm")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Algorithm", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Signature")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Signature", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-SignedHeaders", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Credential")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Credential", valid_600552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600554: Call_RegisterOnPremisesInstance_600542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ## 
  let valid = call_600554.validator(path, query, header, formData, body)
  let scheme = call_600554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600554.url(scheme.get, call_600554.host, call_600554.base,
                         call_600554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600554, url, valid)

proc call*(call_600555: Call_RegisterOnPremisesInstance_600542; body: JsonNode): Recallable =
  ## registerOnPremisesInstance
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ##   body: JObject (required)
  var body_600556 = newJObject()
  if body != nil:
    body_600556 = body
  result = call_600555.call(nil, nil, nil, nil, body_600556)

var registerOnPremisesInstance* = Call_RegisterOnPremisesInstance_600542(
    name: "registerOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterOnPremisesInstance",
    validator: validate_RegisterOnPremisesInstance_600543, base: "/",
    url: url_RegisterOnPremisesInstance_600544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromOnPremisesInstances_600557 = ref object of OpenApiRestCall_599368
proc url_RemoveTagsFromOnPremisesInstances_600559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromOnPremisesInstances_600558(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600560 = header.getOrDefault("X-Amz-Date")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Date", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Security-Token")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Security-Token", valid_600561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600562 = header.getOrDefault("X-Amz-Target")
  valid_600562 = validateParameter(valid_600562, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"))
  if valid_600562 != nil:
    section.add "X-Amz-Target", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Content-Sha256", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Algorithm")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Algorithm", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Signature")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Signature", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-SignedHeaders", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Credential")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Credential", valid_600567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600569: Call_RemoveTagsFromOnPremisesInstances_600557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes one or more tags from one or more on-premises instances.
  ## 
  let valid = call_600569.validator(path, query, header, formData, body)
  let scheme = call_600569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600569.url(scheme.get, call_600569.host, call_600569.base,
                         call_600569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600569, url, valid)

proc call*(call_600570: Call_RemoveTagsFromOnPremisesInstances_600557;
          body: JsonNode): Recallable =
  ## removeTagsFromOnPremisesInstances
  ## Removes one or more tags from one or more on-premises instances.
  ##   body: JObject (required)
  var body_600571 = newJObject()
  if body != nil:
    body_600571 = body
  result = call_600570.call(nil, nil, nil, nil, body_600571)

var removeTagsFromOnPremisesInstances* = Call_RemoveTagsFromOnPremisesInstances_600557(
    name: "removeTagsFromOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances",
    validator: validate_RemoveTagsFromOnPremisesInstances_600558, base: "/",
    url: url_RemoveTagsFromOnPremisesInstances_600559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SkipWaitTimeForInstanceTermination_600572 = ref object of OpenApiRestCall_599368
proc url_SkipWaitTimeForInstanceTermination_600574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SkipWaitTimeForInstanceTermination_600573(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600575 = header.getOrDefault("X-Amz-Date")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Date", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Security-Token")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Security-Token", valid_600576
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600577 = header.getOrDefault("X-Amz-Target")
  valid_600577 = validateParameter(valid_600577, JString, required = true, default = newJString(
      "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"))
  if valid_600577 != nil:
    section.add "X-Amz-Target", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Content-Sha256", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Algorithm")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Algorithm", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Signature")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Signature", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-SignedHeaders", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Credential")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Credential", valid_600582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600584: Call_SkipWaitTimeForInstanceTermination_600572;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ## 
  let valid = call_600584.validator(path, query, header, formData, body)
  let scheme = call_600584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600584.url(scheme.get, call_600584.host, call_600584.base,
                         call_600584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600584, url, valid)

proc call*(call_600585: Call_SkipWaitTimeForInstanceTermination_600572;
          body: JsonNode): Recallable =
  ## skipWaitTimeForInstanceTermination
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ##   body: JObject (required)
  var body_600586 = newJObject()
  if body != nil:
    body_600586 = body
  result = call_600585.call(nil, nil, nil, nil, body_600586)

var skipWaitTimeForInstanceTermination* = Call_SkipWaitTimeForInstanceTermination_600572(
    name: "skipWaitTimeForInstanceTermination", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.SkipWaitTimeForInstanceTermination",
    validator: validate_SkipWaitTimeForInstanceTermination_600573, base: "/",
    url: url_SkipWaitTimeForInstanceTermination_600574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_600587 = ref object of OpenApiRestCall_599368
proc url_StopDeployment_600589(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDeployment_600588(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600590 = header.getOrDefault("X-Amz-Date")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Date", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Security-Token")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Security-Token", valid_600591
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600592 = header.getOrDefault("X-Amz-Target")
  valid_600592 = validateParameter(valid_600592, JString, required = true, default = newJString(
      "CodeDeploy_20141006.StopDeployment"))
  if valid_600592 != nil:
    section.add "X-Amz-Target", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Content-Sha256", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Algorithm")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Algorithm", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Signature")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Signature", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-SignedHeaders", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Credential")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Credential", valid_600597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600599: Call_StopDeployment_600587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop an ongoing deployment.
  ## 
  let valid = call_600599.validator(path, query, header, formData, body)
  let scheme = call_600599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600599.url(scheme.get, call_600599.host, call_600599.base,
                         call_600599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600599, url, valid)

proc call*(call_600600: Call_StopDeployment_600587; body: JsonNode): Recallable =
  ## stopDeployment
  ## Attempts to stop an ongoing deployment.
  ##   body: JObject (required)
  var body_600601 = newJObject()
  if body != nil:
    body_600601 = body
  result = call_600600.call(nil, nil, nil, nil, body_600601)

var stopDeployment* = Call_StopDeployment_600587(name: "stopDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.StopDeployment",
    validator: validate_StopDeployment_600588, base: "/", url: url_StopDeployment_600589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600602 = ref object of OpenApiRestCall_599368
proc url_TagResource_600604(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600605 = header.getOrDefault("X-Amz-Date")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Date", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Security-Token")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Security-Token", valid_600606
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600607 = header.getOrDefault("X-Amz-Target")
  valid_600607 = validateParameter(valid_600607, JString, required = true, default = newJString(
      "CodeDeploy_20141006.TagResource"))
  if valid_600607 != nil:
    section.add "X-Amz-Target", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Content-Sha256", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Algorithm")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Algorithm", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Signature")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Signature", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-SignedHeaders", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Credential")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Credential", valid_600612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600614: Call_TagResource_600602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ## 
  let valid = call_600614.validator(path, query, header, formData, body)
  let scheme = call_600614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600614.url(scheme.get, call_600614.host, call_600614.base,
                         call_600614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600614, url, valid)

proc call*(call_600615: Call_TagResource_600602; body: JsonNode): Recallable =
  ## tagResource
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ##   body: JObject (required)
  var body_600616 = newJObject()
  if body != nil:
    body_600616 = body
  result = call_600615.call(nil, nil, nil, nil, body_600616)

var tagResource* = Call_TagResource_600602(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.TagResource",
                                        validator: validate_TagResource_600603,
                                        base: "/", url: url_TagResource_600604,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600617 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600619(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600620 = header.getOrDefault("X-Amz-Date")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Date", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Security-Token")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Security-Token", valid_600621
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600622 = header.getOrDefault("X-Amz-Target")
  valid_600622 = validateParameter(valid_600622, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UntagResource"))
  if valid_600622 != nil:
    section.add "X-Amz-Target", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Content-Sha256", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Algorithm")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Algorithm", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Signature")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Signature", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-SignedHeaders", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Credential")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Credential", valid_600627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600629: Call_UntagResource_600617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ## 
  let valid = call_600629.validator(path, query, header, formData, body)
  let scheme = call_600629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600629.url(scheme.get, call_600629.host, call_600629.base,
                         call_600629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600629, url, valid)

proc call*(call_600630: Call_UntagResource_600617; body: JsonNode): Recallable =
  ## untagResource
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ##   body: JObject (required)
  var body_600631 = newJObject()
  if body != nil:
    body_600631 = body
  result = call_600630.call(nil, nil, nil, nil, body_600631)

var untagResource* = Call_UntagResource_600617(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UntagResource",
    validator: validate_UntagResource_600618, base: "/", url: url_UntagResource_600619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_600632 = ref object of OpenApiRestCall_599368
proc url_UpdateApplication_600634(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_600633(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600635 = header.getOrDefault("X-Amz-Date")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Date", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Security-Token")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Security-Token", valid_600636
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600637 = header.getOrDefault("X-Amz-Target")
  valid_600637 = validateParameter(valid_600637, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateApplication"))
  if valid_600637 != nil:
    section.add "X-Amz-Target", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Content-Sha256", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Algorithm")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Algorithm", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Signature")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Signature", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-SignedHeaders", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Credential")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Credential", valid_600642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600644: Call_UpdateApplication_600632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the name of an application.
  ## 
  let valid = call_600644.validator(path, query, header, formData, body)
  let scheme = call_600644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600644.url(scheme.get, call_600644.host, call_600644.base,
                         call_600644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600644, url, valid)

proc call*(call_600645: Call_UpdateApplication_600632; body: JsonNode): Recallable =
  ## updateApplication
  ## Changes the name of an application.
  ##   body: JObject (required)
  var body_600646 = newJObject()
  if body != nil:
    body_600646 = body
  result = call_600645.call(nil, nil, nil, nil, body_600646)

var updateApplication* = Call_UpdateApplication_600632(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateApplication",
    validator: validate_UpdateApplication_600633, base: "/",
    url: url_UpdateApplication_600634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentGroup_600647 = ref object of OpenApiRestCall_599368
proc url_UpdateDeploymentGroup_600649(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeploymentGroup_600648(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600650 = header.getOrDefault("X-Amz-Date")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Date", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Security-Token")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Security-Token", valid_600651
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600652 = header.getOrDefault("X-Amz-Target")
  valid_600652 = validateParameter(valid_600652, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateDeploymentGroup"))
  if valid_600652 != nil:
    section.add "X-Amz-Target", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Content-Sha256", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Algorithm")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Algorithm", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Signature")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Signature", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-SignedHeaders", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Credential")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Credential", valid_600657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600659: Call_UpdateDeploymentGroup_600647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a deployment group.
  ## 
  let valid = call_600659.validator(path, query, header, formData, body)
  let scheme = call_600659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600659.url(scheme.get, call_600659.host, call_600659.base,
                         call_600659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600659, url, valid)

proc call*(call_600660: Call_UpdateDeploymentGroup_600647; body: JsonNode): Recallable =
  ## updateDeploymentGroup
  ## Changes information about a deployment group.
  ##   body: JObject (required)
  var body_600661 = newJObject()
  if body != nil:
    body_600661 = body
  result = call_600660.call(nil, nil, nil, nil, body_600661)

var updateDeploymentGroup* = Call_UpdateDeploymentGroup_600647(
    name: "updateDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateDeploymentGroup",
    validator: validate_UpdateDeploymentGroup_600648, base: "/",
    url: url_UpdateDeploymentGroup_600649, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
