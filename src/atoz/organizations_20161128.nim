
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Organizations
## version: 2016-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Organizations API Reference</fullname> <p>AWS Organizations is a web service that enables you to consolidate your multiple AWS accounts into an <i>organization</i> and centrally manage your accounts and their resources.</p> <p>This guide provides descriptions of the Organizations API. For more information about using this service, see the <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html">AWS Organizations User Guide</a>.</p> <p> <b>API Version</b> </p> <p>This version of the Organizations API Reference documents the Organizations API version 2016-11-28.</p> <note> <p>As an alternative to using the API directly, you can use one of the AWS SDKs, which consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .NET, iOS, Android, and more). The SDKs provide a convenient way to create programmatic access to AWS Organizations. For example, the SDKs take care of cryptographically signing requests, managing errors, and retrying requests automatically. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note> <p>We recommend that you use the AWS SDKs to make programmatic API calls to Organizations. However, you also can use the Organizations Query API to make direct calls to the Organizations web service. To learn more about the Organizations Query API, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_query-requests.html">Making Query Requests</a> in the <i>AWS Organizations User Guide</i>. Organizations supports GET and POST requests for all actions. That is, the API does not require you to use GET for some actions and POST for others. However, GET requests are subject to the limitation size of a URL. Therefore, for operations that require larger sizes, use a POST request.</p> <p> <b>Signing Requests</b> </p> <p>When you send HTTP requests to AWS, you must sign the requests so that AWS can identify who sent them. You sign requests with your AWS access key, which consists of an access key ID and a secret access key. We strongly recommend that you do not create an access key for your root account. Anyone who has the access key for your root account has unrestricted access to all the resources in your account. Instead, create an access key for an IAM user account that has administrative privileges. As another option, use AWS Security Token Service to generate temporary security credentials, and use those credentials to sign requests. </p> <p>To sign requests, we recommend that you use <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4</a>. If you have an existing application that uses Signature Version 2, you do not have to update it to use Signature Version 4. However, some operations now require Signature Version 4. The documentation for operations that require version 4 indicate this requirement. </p> <p>When you use the AWS Command Line Interface (AWS CLI) or one of the AWS SDKs to make requests to AWS, these tools automatically sign the requests for you with the access key that you specify when you configure the tools.</p> <p>In this release, each organization can have only one root. In a future release, a single organization will support multiple roots.</p> <p> <b>Support and Feedback for AWS Organizations</b> </p> <p>We welcome your feedback. Send your comments to <a href="mailto:feedback-awsorganizations@amazon.com">feedback-awsorganizations@amazon.com</a> or post your feedback and questions in the <a href="http://forums.aws.amazon.com/forum.jspa?forumID=219">AWS Organizations support forum</a>. For more information about the AWS support forums, see <a href="http://forums.aws.amazon.com/help.jspa">Forums Help</a>.</p> <p> <b>Endpoint to Call When Using the CLI or the AWS API</b> </p> <p>For the current release of Organizations, you must specify the <code>us-east-1</code> region for all AWS API and CLI calls. You can do this in the CLI by using these parameters and commands:</p> <ul> <li> <p>Use the following parameter with each command to specify both the endpoint and its region:</p> <p> <code>--endpoint-url https://organizations.us-east-1.amazonaws.com</code> </p> </li> <li> <p>Use the default endpoint, but configure your default region with this command:</p> <p> <code>aws configure set default.region us-east-1</code> </p> </li> <li> <p>Use the following parameter with each command to specify the endpoint:</p> <p> <code>--region us-east-1</code> </p> </li> </ul> <p>For the various SDKs used to call the APIs, see the documentation for the SDK of interest to learn how to direct the requests to a specific endpoint. For more information, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#sts_region">Regions and Endpoints</a> in the <i>AWS General Reference</i>. </p> <p> <b>How examples are presented</b> </p> <p>The JSON returned by the AWS Organizations service as response to your requests is returned as a single long string without line breaks or formatting whitespace. Both line breaks and whitespace are included in the examples in this guide to improve readability. When example input parameters also would result in long strings that would extend beyond the screen, we insert line breaks to enhance readability. You should always submit the input as a single JSON text string.</p> <p> <b>Recording API Requests</b> </p> <p>AWS Organizations supports AWS CloudTrail, a service that records AWS API calls for your AWS account and delivers log files to an Amazon S3 bucket. By using information collected by AWS CloudTrail, you can determine which requests were successfully made to Organizations, who made the request, when it was made, and so on. For more about AWS Organizations and its support for AWS CloudTrail, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html#orgs_cloudtrail-integration">Logging AWS Organizations Events with AWS CloudTrail</a> in the <i>AWS Organizations User Guide</i>. To learn more about CloudTrail, including how to turn it on and find your log files, see the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/what_is_cloud_trail_top_level.html">AWS CloudTrail User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/organizations/
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

  OpenApiRestCall_592365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592365): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "organizations.ap-northeast-1.amazonaws.com", "ap-southeast-1": "organizations.ap-southeast-1.amazonaws.com", "us-west-2": "organizations.us-west-2.amazonaws.com", "eu-west-2": "organizations.eu-west-2.amazonaws.com", "ap-northeast-3": "organizations.ap-northeast-3.amazonaws.com", "eu-central-1": "organizations.eu-central-1.amazonaws.com", "us-east-2": "organizations.us-east-2.amazonaws.com", "us-east-1": "organizations.us-east-1.amazonaws.com", "cn-northwest-1": "organizations.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "organizations.ap-south-1.amazonaws.com", "eu-north-1": "organizations.eu-north-1.amazonaws.com", "ap-northeast-2": "organizations.ap-northeast-2.amazonaws.com", "us-west-1": "organizations.us-west-1.amazonaws.com", "us-gov-east-1": "organizations.us-gov-east-1.amazonaws.com", "eu-west-3": "organizations.eu-west-3.amazonaws.com", "cn-north-1": "organizations.cn-north-1.amazonaws.com.cn", "sa-east-1": "organizations.sa-east-1.amazonaws.com", "eu-west-1": "organizations.eu-west-1.amazonaws.com", "us-gov-west-1": "organizations.us-gov-west-1.amazonaws.com", "ap-southeast-2": "organizations.ap-southeast-2.amazonaws.com", "ca-central-1": "organizations.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "organizations.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "organizations.ap-southeast-1.amazonaws.com",
      "us-west-2": "organizations.us-west-2.amazonaws.com",
      "eu-west-2": "organizations.eu-west-2.amazonaws.com",
      "ap-northeast-3": "organizations.ap-northeast-3.amazonaws.com",
      "eu-central-1": "organizations.eu-central-1.amazonaws.com",
      "us-east-2": "organizations.us-east-2.amazonaws.com",
      "us-east-1": "organizations.us-east-1.amazonaws.com",
      "cn-northwest-1": "organizations.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "organizations.ap-south-1.amazonaws.com",
      "eu-north-1": "organizations.eu-north-1.amazonaws.com",
      "ap-northeast-2": "organizations.ap-northeast-2.amazonaws.com",
      "us-west-1": "organizations.us-west-1.amazonaws.com",
      "us-gov-east-1": "organizations.us-gov-east-1.amazonaws.com",
      "eu-west-3": "organizations.eu-west-3.amazonaws.com",
      "cn-north-1": "organizations.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "organizations.sa-east-1.amazonaws.com",
      "eu-west-1": "organizations.eu-west-1.amazonaws.com",
      "us-gov-west-1": "organizations.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "organizations.ap-southeast-2.amazonaws.com",
      "ca-central-1": "organizations.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "organizations"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptHandshake_592704 = ref object of OpenApiRestCall_592365
proc url_AcceptHandshake_592706(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptHandshake_592705(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
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
  var valid_592831 = header.getOrDefault("X-Amz-Target")
  valid_592831 = validateParameter(valid_592831, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AcceptHandshake"))
  if valid_592831 != nil:
    section.add "X-Amz-Target", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_AcceptHandshake_592704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_AcceptHandshake_592704; body: JsonNode): Recallable =
  ## acceptHandshake
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_592934 = newJObject()
  if body != nil:
    body_592934 = body
  result = call_592933.call(nil, nil, nil, nil, body_592934)

var acceptHandshake* = Call_AcceptHandshake_592704(name: "acceptHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AcceptHandshake",
    validator: validate_AcceptHandshake_592705, base: "/", url: url_AcceptHandshake_592706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_592973 = ref object of OpenApiRestCall_592365
proc url_AttachPolicy_592975(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachPolicy_592974(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_592976 = header.getOrDefault("X-Amz-Target")
  valid_592976 = validateParameter(valid_592976, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AttachPolicy"))
  if valid_592976 != nil:
    section.add "X-Amz-Target", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592985: Call_AttachPolicy_592973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_592985.validator(path, query, header, formData, body)
  let scheme = call_592985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592985.url(scheme.get, call_592985.host, call_592985.base,
                         call_592985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592985, url, valid)

proc call*(call_592986: Call_AttachPolicy_592973; body: JsonNode): Recallable =
  ## attachPolicy
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_592987 = newJObject()
  if body != nil:
    body_592987 = body
  result = call_592986.call(nil, nil, nil, nil, body_592987)

var attachPolicy* = Call_AttachPolicy_592973(name: "attachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AttachPolicy",
    validator: validate_AttachPolicy_592974, base: "/", url: url_AttachPolicy_592975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelHandshake_592988 = ref object of OpenApiRestCall_592365
proc url_CancelHandshake_592990(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelHandshake_592989(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
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
  var valid_592991 = header.getOrDefault("X-Amz-Target")
  valid_592991 = validateParameter(valid_592991, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CancelHandshake"))
  if valid_592991 != nil:
    section.add "X-Amz-Target", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Signature")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Signature", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Content-Sha256", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Date")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Date", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Credential")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Credential", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Security-Token")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Security-Token", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Algorithm")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Algorithm", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-SignedHeaders", valid_592998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_CancelHandshake_592988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_CancelHandshake_592988; body: JsonNode): Recallable =
  ## cancelHandshake
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_593002 = newJObject()
  if body != nil:
    body_593002 = body
  result = call_593001.call(nil, nil, nil, nil, body_593002)

var cancelHandshake* = Call_CancelHandshake_592988(name: "cancelHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CancelHandshake",
    validator: validate_CancelHandshake_592989, base: "/", url: url_CancelHandshake_592990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_593003 = ref object of OpenApiRestCall_592365
proc url_CreateAccount_593005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAccount_593004(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
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
  var valid_593006 = header.getOrDefault("X-Amz-Target")
  valid_593006 = validateParameter(valid_593006, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateAccount"))
  if valid_593006 != nil:
    section.add "X-Amz-Target", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Algorithm")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Algorithm", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-SignedHeaders", valid_593013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_CreateAccount_593003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_CreateAccount_593003; body: JsonNode): Recallable =
  ## createAccount
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_593017 = newJObject()
  if body != nil:
    body_593017 = body
  result = call_593016.call(nil, nil, nil, nil, body_593017)

var createAccount* = Call_CreateAccount_593003(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateAccount",
    validator: validate_CreateAccount_593004, base: "/", url: url_CreateAccount_593005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGovCloudAccount_593018 = ref object of OpenApiRestCall_592365
proc url_CreateGovCloudAccount_593020(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGovCloudAccount_593019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
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
  var valid_593021 = header.getOrDefault("X-Amz-Target")
  valid_593021 = validateParameter(valid_593021, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateGovCloudAccount"))
  if valid_593021 != nil:
    section.add "X-Amz-Target", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593030: Call_CreateGovCloudAccount_593018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_593030.validator(path, query, header, formData, body)
  let scheme = call_593030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593030.url(scheme.get, call_593030.host, call_593030.base,
                         call_593030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593030, url, valid)

proc call*(call_593031: Call_CreateGovCloudAccount_593018; body: JsonNode): Recallable =
  ## createGovCloudAccount
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_593032 = newJObject()
  if body != nil:
    body_593032 = body
  result = call_593031.call(nil, nil, nil, nil, body_593032)

var createGovCloudAccount* = Call_CreateGovCloudAccount_593018(
    name: "createGovCloudAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateGovCloudAccount",
    validator: validate_CreateGovCloudAccount_593019, base: "/",
    url: url_CreateGovCloudAccount_593020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganization_593033 = ref object of OpenApiRestCall_592365
proc url_CreateOrganization_593035(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOrganization_593034(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
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
  var valid_593036 = header.getOrDefault("X-Amz-Target")
  valid_593036 = validateParameter(valid_593036, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganization"))
  if valid_593036 != nil:
    section.add "X-Amz-Target", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_CreateOrganization_593033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_CreateOrganization_593033; body: JsonNode): Recallable =
  ## createOrganization
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ##   body: JObject (required)
  var body_593047 = newJObject()
  if body != nil:
    body_593047 = body
  result = call_593046.call(nil, nil, nil, nil, body_593047)

var createOrganization* = Call_CreateOrganization_593033(
    name: "createOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganization",
    validator: validate_CreateOrganization_593034, base: "/",
    url: url_CreateOrganization_593035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganizationalUnit_593048 = ref object of OpenApiRestCall_592365
proc url_CreateOrganizationalUnit_593050(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOrganizationalUnit_593049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593051 = header.getOrDefault("X-Amz-Target")
  valid_593051 = validateParameter(valid_593051, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganizationalUnit"))
  if valid_593051 != nil:
    section.add "X-Amz-Target", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_CreateOrganizationalUnit_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_CreateOrganizationalUnit_593048; body: JsonNode): Recallable =
  ## createOrganizationalUnit
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593062 = newJObject()
  if body != nil:
    body_593062 = body
  result = call_593061.call(nil, nil, nil, nil, body_593062)

var createOrganizationalUnit* = Call_CreateOrganizationalUnit_593048(
    name: "createOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganizationalUnit",
    validator: validate_CreateOrganizationalUnit_593049, base: "/",
    url: url_CreateOrganizationalUnit_593050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePolicy_593063 = ref object of OpenApiRestCall_592365
proc url_CreatePolicy_593065(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePolicy_593064(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593066 = header.getOrDefault("X-Amz-Target")
  valid_593066 = validateParameter(valid_593066, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreatePolicy"))
  if valid_593066 != nil:
    section.add "X-Amz-Target", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Signature")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Signature", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Content-Sha256", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Date")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Date", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Credential")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Credential", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Security-Token")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Security-Token", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Algorithm")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Algorithm", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-SignedHeaders", valid_593073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_CreatePolicy_593063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_CreatePolicy_593063; body: JsonNode): Recallable =
  ## createPolicy
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593077 = newJObject()
  if body != nil:
    body_593077 = body
  result = call_593076.call(nil, nil, nil, nil, body_593077)

var createPolicy* = Call_CreatePolicy_593063(name: "createPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreatePolicy",
    validator: validate_CreatePolicy_593064, base: "/", url: url_CreatePolicy_593065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineHandshake_593078 = ref object of OpenApiRestCall_592365
proc url_DeclineHandshake_593080(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeclineHandshake_593079(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
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
  var valid_593081 = header.getOrDefault("X-Amz-Target")
  valid_593081 = validateParameter(valid_593081, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeclineHandshake"))
  if valid_593081 != nil:
    section.add "X-Amz-Target", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Signature")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Signature", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Content-Sha256", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Date")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Date", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Credential")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Credential", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Security-Token")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Security-Token", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Algorithm")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Algorithm", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-SignedHeaders", valid_593088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593090: Call_DeclineHandshake_593078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_DeclineHandshake_593078; body: JsonNode): Recallable =
  ## declineHandshake
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_593092 = newJObject()
  if body != nil:
    body_593092 = body
  result = call_593091.call(nil, nil, nil, nil, body_593092)

var declineHandshake* = Call_DeclineHandshake_593078(name: "declineHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeclineHandshake",
    validator: validate_DeclineHandshake_593079, base: "/",
    url: url_DeclineHandshake_593080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganization_593093 = ref object of OpenApiRestCall_592365
proc url_DeleteOrganization_593095(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteOrganization_593094(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
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
  var valid_593096 = header.getOrDefault("X-Amz-Target")
  valid_593096 = validateParameter(valid_593096, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganization"))
  if valid_593096 != nil:
    section.add "X-Amz-Target", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_DeleteOrganization_593093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_DeleteOrganization_593093): Recallable =
  ## deleteOrganization
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  result = call_593105.call(nil, nil, nil, nil, nil)

var deleteOrganization* = Call_DeleteOrganization_593093(
    name: "deleteOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganization",
    validator: validate_DeleteOrganization_593094, base: "/",
    url: url_DeleteOrganization_593095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationalUnit_593106 = ref object of OpenApiRestCall_592365
proc url_DeleteOrganizationalUnit_593108(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteOrganizationalUnit_593107(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593109 = header.getOrDefault("X-Amz-Target")
  valid_593109 = validateParameter(valid_593109, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganizationalUnit"))
  if valid_593109 != nil:
    section.add "X-Amz-Target", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Signature")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Signature", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Content-Sha256", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Date")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Date", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Credential")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Credential", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Security-Token")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Security-Token", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Algorithm")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Algorithm", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-SignedHeaders", valid_593116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_DeleteOrganizationalUnit_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_DeleteOrganizationalUnit_593106; body: JsonNode): Recallable =
  ## deleteOrganizationalUnit
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593120 = newJObject()
  if body != nil:
    body_593120 = body
  result = call_593119.call(nil, nil, nil, nil, body_593120)

var deleteOrganizationalUnit* = Call_DeleteOrganizationalUnit_593106(
    name: "deleteOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganizationalUnit",
    validator: validate_DeleteOrganizationalUnit_593107, base: "/",
    url: url_DeleteOrganizationalUnit_593108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_593121 = ref object of OpenApiRestCall_592365
proc url_DeletePolicy_593123(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePolicy_593122(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593124 = header.getOrDefault("X-Amz-Target")
  valid_593124 = validateParameter(valid_593124, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeletePolicy"))
  if valid_593124 != nil:
    section.add "X-Amz-Target", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Signature")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Signature", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Content-Sha256", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Date")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Date", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Credential")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Credential", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Security-Token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Security-Token", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Algorithm")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Algorithm", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-SignedHeaders", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593133: Call_DeletePolicy_593121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593133.validator(path, query, header, formData, body)
  let scheme = call_593133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593133.url(scheme.get, call_593133.host, call_593133.base,
                         call_593133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593133, url, valid)

proc call*(call_593134: Call_DeletePolicy_593121; body: JsonNode): Recallable =
  ## deletePolicy
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593135 = newJObject()
  if body != nil:
    body_593135 = body
  result = call_593134.call(nil, nil, nil, nil, body_593135)

var deletePolicy* = Call_DeletePolicy_593121(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeletePolicy",
    validator: validate_DeletePolicy_593122, base: "/", url: url_DeletePolicy_593123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_593136 = ref object of OpenApiRestCall_592365
proc url_DescribeAccount_593138(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccount_593137(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593139 = header.getOrDefault("X-Amz-Target")
  valid_593139 = validateParameter(valid_593139, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeAccount"))
  if valid_593139 != nil:
    section.add "X-Amz-Target", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Signature")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Signature", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Content-Sha256", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Date")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Date", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Credential")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Credential", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Security-Token")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Security-Token", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Algorithm")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Algorithm", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-SignedHeaders", valid_593146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593148: Call_DescribeAccount_593136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593148.validator(path, query, header, formData, body)
  let scheme = call_593148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593148.url(scheme.get, call_593148.host, call_593148.base,
                         call_593148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593148, url, valid)

proc call*(call_593149: Call_DescribeAccount_593136; body: JsonNode): Recallable =
  ## describeAccount
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593150 = newJObject()
  if body != nil:
    body_593150 = body
  result = call_593149.call(nil, nil, nil, nil, body_593150)

var describeAccount* = Call_DescribeAccount_593136(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeAccount",
    validator: validate_DescribeAccount_593137, base: "/", url: url_DescribeAccount_593138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCreateAccountStatus_593151 = ref object of OpenApiRestCall_592365
proc url_DescribeCreateAccountStatus_593153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCreateAccountStatus_593152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593154 = header.getOrDefault("X-Amz-Target")
  valid_593154 = validateParameter(valid_593154, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeCreateAccountStatus"))
  if valid_593154 != nil:
    section.add "X-Amz-Target", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Signature")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Signature", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Content-Sha256", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Date")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Date", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Credential")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Credential", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Security-Token")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Security-Token", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Algorithm")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Algorithm", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-SignedHeaders", valid_593161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_DescribeCreateAccountStatus_593151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_DescribeCreateAccountStatus_593151; body: JsonNode): Recallable =
  ## describeCreateAccountStatus
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593165 = newJObject()
  if body != nil:
    body_593165 = body
  result = call_593164.call(nil, nil, nil, nil, body_593165)

var describeCreateAccountStatus* = Call_DescribeCreateAccountStatus_593151(
    name: "describeCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeCreateAccountStatus",
    validator: validate_DescribeCreateAccountStatus_593152, base: "/",
    url: url_DescribeCreateAccountStatus_593153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHandshake_593166 = ref object of OpenApiRestCall_592365
proc url_DescribeHandshake_593168(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeHandshake_593167(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
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
  var valid_593169 = header.getOrDefault("X-Amz-Target")
  valid_593169 = validateParameter(valid_593169, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeHandshake"))
  if valid_593169 != nil:
    section.add "X-Amz-Target", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Signature")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Signature", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Content-Sha256", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Date")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Date", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Credential")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Credential", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Security-Token")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Security-Token", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Algorithm")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Algorithm", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-SignedHeaders", valid_593176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593178: Call_DescribeHandshake_593166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_593178.validator(path, query, header, formData, body)
  let scheme = call_593178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593178.url(scheme.get, call_593178.host, call_593178.base,
                         call_593178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593178, url, valid)

proc call*(call_593179: Call_DescribeHandshake_593166; body: JsonNode): Recallable =
  ## describeHandshake
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_593180 = newJObject()
  if body != nil:
    body_593180 = body
  result = call_593179.call(nil, nil, nil, nil, body_593180)

var describeHandshake* = Call_DescribeHandshake_593166(name: "describeHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeHandshake",
    validator: validate_DescribeHandshake_593167, base: "/",
    url: url_DescribeHandshake_593168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_593181 = ref object of OpenApiRestCall_592365
proc url_DescribeOrganization_593183(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganization_593182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
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
  var valid_593184 = header.getOrDefault("X-Amz-Target")
  valid_593184 = validateParameter(valid_593184, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganization"))
  if valid_593184 != nil:
    section.add "X-Amz-Target", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Signature")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Signature", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Content-Sha256", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Date")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Date", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Credential")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Credential", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Security-Token")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Security-Token", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Algorithm")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Algorithm", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-SignedHeaders", valid_593191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_DescribeOrganization_593181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_DescribeOrganization_593181): Recallable =
  ## describeOrganization
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  result = call_593193.call(nil, nil, nil, nil, nil)

var describeOrganization* = Call_DescribeOrganization_593181(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganization",
    validator: validate_DescribeOrganization_593182, base: "/",
    url: url_DescribeOrganization_593183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationalUnit_593194 = ref object of OpenApiRestCall_592365
proc url_DescribeOrganizationalUnit_593196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganizationalUnit_593195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593197 = header.getOrDefault("X-Amz-Target")
  valid_593197 = validateParameter(valid_593197, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganizationalUnit"))
  if valid_593197 != nil:
    section.add "X-Amz-Target", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Signature")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Signature", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Content-Sha256", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Date")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Date", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Credential")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Credential", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Security-Token")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Security-Token", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Algorithm")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Algorithm", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-SignedHeaders", valid_593204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593206: Call_DescribeOrganizationalUnit_593194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593206.validator(path, query, header, formData, body)
  let scheme = call_593206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593206.url(scheme.get, call_593206.host, call_593206.base,
                         call_593206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593206, url, valid)

proc call*(call_593207: Call_DescribeOrganizationalUnit_593194; body: JsonNode): Recallable =
  ## describeOrganizationalUnit
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593208 = newJObject()
  if body != nil:
    body_593208 = body
  result = call_593207.call(nil, nil, nil, nil, body_593208)

var describeOrganizationalUnit* = Call_DescribeOrganizationalUnit_593194(
    name: "describeOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganizationalUnit",
    validator: validate_DescribeOrganizationalUnit_593195, base: "/",
    url: url_DescribeOrganizationalUnit_593196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePolicy_593209 = ref object of OpenApiRestCall_592365
proc url_DescribePolicy_593211(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePolicy_593210(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593212 = header.getOrDefault("X-Amz-Target")
  valid_593212 = validateParameter(valid_593212, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribePolicy"))
  if valid_593212 != nil:
    section.add "X-Amz-Target", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Signature")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Signature", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Content-Sha256", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Date")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Date", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Credential")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Credential", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Security-Token")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Security-Token", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Algorithm")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Algorithm", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-SignedHeaders", valid_593219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593221: Call_DescribePolicy_593209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593221.validator(path, query, header, formData, body)
  let scheme = call_593221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593221.url(scheme.get, call_593221.host, call_593221.base,
                         call_593221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593221, url, valid)

proc call*(call_593222: Call_DescribePolicy_593209; body: JsonNode): Recallable =
  ## describePolicy
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593223 = newJObject()
  if body != nil:
    body_593223 = body
  result = call_593222.call(nil, nil, nil, nil, body_593223)

var describePolicy* = Call_DescribePolicy_593209(name: "describePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribePolicy",
    validator: validate_DescribePolicy_593210, base: "/", url: url_DescribePolicy_593211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_593224 = ref object of OpenApiRestCall_592365
proc url_DetachPolicy_593226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachPolicy_593225(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593227 = header.getOrDefault("X-Amz-Target")
  valid_593227 = validateParameter(valid_593227, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DetachPolicy"))
  if valid_593227 != nil:
    section.add "X-Amz-Target", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Signature")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Signature", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Content-Sha256", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Date")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Date", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Credential")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Credential", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Security-Token")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Security-Token", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Algorithm")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Algorithm", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-SignedHeaders", valid_593234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593236: Call_DetachPolicy_593224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593236.validator(path, query, header, formData, body)
  let scheme = call_593236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593236.url(scheme.get, call_593236.host, call_593236.base,
                         call_593236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593236, url, valid)

proc call*(call_593237: Call_DetachPolicy_593224; body: JsonNode): Recallable =
  ## detachPolicy
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593238 = newJObject()
  if body != nil:
    body_593238 = body
  result = call_593237.call(nil, nil, nil, nil, body_593238)

var detachPolicy* = Call_DetachPolicy_593224(name: "detachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DetachPolicy",
    validator: validate_DetachPolicy_593225, base: "/", url: url_DetachPolicy_593226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSServiceAccess_593239 = ref object of OpenApiRestCall_592365
proc url_DisableAWSServiceAccess_593241(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableAWSServiceAccess_593240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593242 = header.getOrDefault("X-Amz-Target")
  valid_593242 = validateParameter(valid_593242, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisableAWSServiceAccess"))
  if valid_593242 != nil:
    section.add "X-Amz-Target", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Signature")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Signature", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Content-Sha256", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Date")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Date", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Credential")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Credential", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Security-Token")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Security-Token", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Algorithm")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Algorithm", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-SignedHeaders", valid_593249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593251: Call_DisableAWSServiceAccess_593239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593251.validator(path, query, header, formData, body)
  let scheme = call_593251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593251.url(scheme.get, call_593251.host, call_593251.base,
                         call_593251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593251, url, valid)

proc call*(call_593252: Call_DisableAWSServiceAccess_593239; body: JsonNode): Recallable =
  ## disableAWSServiceAccess
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593253 = newJObject()
  if body != nil:
    body_593253 = body
  result = call_593252.call(nil, nil, nil, nil, body_593253)

var disableAWSServiceAccess* = Call_DisableAWSServiceAccess_593239(
    name: "disableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisableAWSServiceAccess",
    validator: validate_DisableAWSServiceAccess_593240, base: "/",
    url: url_DisableAWSServiceAccess_593241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisablePolicyType_593254 = ref object of OpenApiRestCall_592365
proc url_DisablePolicyType_593256(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisablePolicyType_593255(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
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
  var valid_593257 = header.getOrDefault("X-Amz-Target")
  valid_593257 = validateParameter(valid_593257, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisablePolicyType"))
  if valid_593257 != nil:
    section.add "X-Amz-Target", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Signature")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Signature", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Content-Sha256", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Date")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Date", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Credential")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Credential", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Security-Token")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Security-Token", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Algorithm")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Algorithm", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-SignedHeaders", valid_593264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593266: Call_DisablePolicyType_593254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_593266.validator(path, query, header, formData, body)
  let scheme = call_593266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593266.url(scheme.get, call_593266.host, call_593266.base,
                         call_593266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593266, url, valid)

proc call*(call_593267: Call_DisablePolicyType_593254; body: JsonNode): Recallable =
  ## disablePolicyType
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_593268 = newJObject()
  if body != nil:
    body_593268 = body
  result = call_593267.call(nil, nil, nil, nil, body_593268)

var disablePolicyType* = Call_DisablePolicyType_593254(name: "disablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisablePolicyType",
    validator: validate_DisablePolicyType_593255, base: "/",
    url: url_DisablePolicyType_593256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSServiceAccess_593269 = ref object of OpenApiRestCall_592365
proc url_EnableAWSServiceAccess_593271(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAWSServiceAccess_593270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
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
  var valid_593272 = header.getOrDefault("X-Amz-Target")
  valid_593272 = validateParameter(valid_593272, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAWSServiceAccess"))
  if valid_593272 != nil:
    section.add "X-Amz-Target", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Signature")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Signature", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Content-Sha256", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Date")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Date", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Credential")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Credential", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Security-Token")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Security-Token", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Algorithm")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Algorithm", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-SignedHeaders", valid_593279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593281: Call_EnableAWSServiceAccess_593269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ## 
  let valid = call_593281.validator(path, query, header, formData, body)
  let scheme = call_593281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593281.url(scheme.get, call_593281.host, call_593281.base,
                         call_593281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593281, url, valid)

proc call*(call_593282: Call_EnableAWSServiceAccess_593269; body: JsonNode): Recallable =
  ## enableAWSServiceAccess
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ##   body: JObject (required)
  var body_593283 = newJObject()
  if body != nil:
    body_593283 = body
  result = call_593282.call(nil, nil, nil, nil, body_593283)

var enableAWSServiceAccess* = Call_EnableAWSServiceAccess_593269(
    name: "enableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAWSServiceAccess",
    validator: validate_EnableAWSServiceAccess_593270, base: "/",
    url: url_EnableAWSServiceAccess_593271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAllFeatures_593284 = ref object of OpenApiRestCall_592365
proc url_EnableAllFeatures_593286(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAllFeatures_593285(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
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
  var valid_593287 = header.getOrDefault("X-Amz-Target")
  valid_593287 = validateParameter(valid_593287, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAllFeatures"))
  if valid_593287 != nil:
    section.add "X-Amz-Target", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Signature")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Signature", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Content-Sha256", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Date")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Date", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Credential")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Credential", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Security-Token")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Security-Token", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Algorithm")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Algorithm", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-SignedHeaders", valid_593294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593296: Call_EnableAllFeatures_593284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ## 
  let valid = call_593296.validator(path, query, header, formData, body)
  let scheme = call_593296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593296.url(scheme.get, call_593296.host, call_593296.base,
                         call_593296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593296, url, valid)

proc call*(call_593297: Call_EnableAllFeatures_593284; body: JsonNode): Recallable =
  ## enableAllFeatures
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ##   body: JObject (required)
  var body_593298 = newJObject()
  if body != nil:
    body_593298 = body
  result = call_593297.call(nil, nil, nil, nil, body_593298)

var enableAllFeatures* = Call_EnableAllFeatures_593284(name: "enableAllFeatures",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAllFeatures",
    validator: validate_EnableAllFeatures_593285, base: "/",
    url: url_EnableAllFeatures_593286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnablePolicyType_593299 = ref object of OpenApiRestCall_592365
proc url_EnablePolicyType_593301(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnablePolicyType_593300(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
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
  var valid_593302 = header.getOrDefault("X-Amz-Target")
  valid_593302 = validateParameter(valid_593302, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnablePolicyType"))
  if valid_593302 != nil:
    section.add "X-Amz-Target", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Signature")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Signature", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Content-Sha256", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Date")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Date", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Credential")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Credential", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Algorithm")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Algorithm", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-SignedHeaders", valid_593309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_EnablePolicyType_593299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_EnablePolicyType_593299; body: JsonNode): Recallable =
  ## enablePolicyType
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_593313 = newJObject()
  if body != nil:
    body_593313 = body
  result = call_593312.call(nil, nil, nil, nil, body_593313)

var enablePolicyType* = Call_EnablePolicyType_593299(name: "enablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnablePolicyType",
    validator: validate_EnablePolicyType_593300, base: "/",
    url: url_EnablePolicyType_593301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteAccountToOrganization_593314 = ref object of OpenApiRestCall_592365
proc url_InviteAccountToOrganization_593316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InviteAccountToOrganization_593315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593317 = header.getOrDefault("X-Amz-Target")
  valid_593317 = validateParameter(valid_593317, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.InviteAccountToOrganization"))
  if valid_593317 != nil:
    section.add "X-Amz-Target", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Signature")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Signature", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Content-Sha256", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Date")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Date", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Credential")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Credential", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Security-Token")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Security-Token", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Algorithm")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Algorithm", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-SignedHeaders", valid_593324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593326: Call_InviteAccountToOrganization_593314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593326.validator(path, query, header, formData, body)
  let scheme = call_593326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593326.url(scheme.get, call_593326.host, call_593326.base,
                         call_593326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593326, url, valid)

proc call*(call_593327: Call_InviteAccountToOrganization_593314; body: JsonNode): Recallable =
  ## inviteAccountToOrganization
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593328 = newJObject()
  if body != nil:
    body_593328 = body
  result = call_593327.call(nil, nil, nil, nil, body_593328)

var inviteAccountToOrganization* = Call_InviteAccountToOrganization_593314(
    name: "inviteAccountToOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.InviteAccountToOrganization",
    validator: validate_InviteAccountToOrganization_593315, base: "/",
    url: url_InviteAccountToOrganization_593316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LeaveOrganization_593329 = ref object of OpenApiRestCall_592365
proc url_LeaveOrganization_593331(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LeaveOrganization_593330(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
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
  var valid_593332 = header.getOrDefault("X-Amz-Target")
  valid_593332 = validateParameter(valid_593332, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.LeaveOrganization"))
  if valid_593332 != nil:
    section.add "X-Amz-Target", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Signature")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Signature", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Content-Sha256", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Date")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Date", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Credential")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Credential", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Security-Token")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Security-Token", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Algorithm")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Algorithm", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-SignedHeaders", valid_593339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593340: Call_LeaveOrganization_593329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  ## 
  let valid = call_593340.validator(path, query, header, formData, body)
  let scheme = call_593340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593340.url(scheme.get, call_593340.host, call_593340.base,
                         call_593340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593340, url, valid)

proc call*(call_593341: Call_LeaveOrganization_593329): Recallable =
  ## leaveOrganization
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  result = call_593341.call(nil, nil, nil, nil, nil)

var leaveOrganization* = Call_LeaveOrganization_593329(name: "leaveOrganization",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.LeaveOrganization",
    validator: validate_LeaveOrganization_593330, base: "/",
    url: url_LeaveOrganization_593331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSServiceAccessForOrganization_593342 = ref object of OpenApiRestCall_592365
proc url_ListAWSServiceAccessForOrganization_593344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAWSServiceAccessForOrganization_593343(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593345 = query.getOrDefault("MaxResults")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "MaxResults", valid_593345
  var valid_593346 = query.getOrDefault("NextToken")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "NextToken", valid_593346
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
  var valid_593347 = header.getOrDefault("X-Amz-Target")
  valid_593347 = validateParameter(valid_593347, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"))
  if valid_593347 != nil:
    section.add "X-Amz-Target", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Signature")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Signature", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Content-Sha256", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Date")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Date", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Credential")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Credential", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Security-Token")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Security-Token", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Algorithm")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Algorithm", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-SignedHeaders", valid_593354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_ListAWSServiceAccessForOrganization_593342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_ListAWSServiceAccessForOrganization_593342;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSServiceAccessForOrganization
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593358 = newJObject()
  var body_593359 = newJObject()
  add(query_593358, "MaxResults", newJString(MaxResults))
  add(query_593358, "NextToken", newJString(NextToken))
  if body != nil:
    body_593359 = body
  result = call_593357.call(nil, query_593358, nil, nil, body_593359)

var listAWSServiceAccessForOrganization* = Call_ListAWSServiceAccessForOrganization_593342(
    name: "listAWSServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization",
    validator: validate_ListAWSServiceAccessForOrganization_593343, base: "/",
    url: url_ListAWSServiceAccessForOrganization_593344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_593361 = ref object of OpenApiRestCall_592365
proc url_ListAccounts_593363(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccounts_593362(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593364 = query.getOrDefault("MaxResults")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "MaxResults", valid_593364
  var valid_593365 = query.getOrDefault("NextToken")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "NextToken", valid_593365
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
  var valid_593366 = header.getOrDefault("X-Amz-Target")
  valid_593366 = validateParameter(valid_593366, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccounts"))
  if valid_593366 != nil:
    section.add "X-Amz-Target", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Signature")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Signature", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Content-Sha256", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Date")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Date", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Credential")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Credential", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Security-Token")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Security-Token", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Algorithm")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Algorithm", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-SignedHeaders", valid_593373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593375: Call_ListAccounts_593361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593375.validator(path, query, header, formData, body)
  let scheme = call_593375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593375.url(scheme.get, call_593375.host, call_593375.base,
                         call_593375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593375, url, valid)

proc call*(call_593376: Call_ListAccounts_593361; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccounts
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593377 = newJObject()
  var body_593378 = newJObject()
  add(query_593377, "MaxResults", newJString(MaxResults))
  add(query_593377, "NextToken", newJString(NextToken))
  if body != nil:
    body_593378 = body
  result = call_593376.call(nil, query_593377, nil, nil, body_593378)

var listAccounts* = Call_ListAccounts_593361(name: "listAccounts",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccounts",
    validator: validate_ListAccounts_593362, base: "/", url: url_ListAccounts_593363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountsForParent_593379 = ref object of OpenApiRestCall_592365
proc url_ListAccountsForParent_593381(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccountsForParent_593380(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593382 = query.getOrDefault("MaxResults")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "MaxResults", valid_593382
  var valid_593383 = query.getOrDefault("NextToken")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "NextToken", valid_593383
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
  var valid_593384 = header.getOrDefault("X-Amz-Target")
  valid_593384 = validateParameter(valid_593384, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccountsForParent"))
  if valid_593384 != nil:
    section.add "X-Amz-Target", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Signature")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Signature", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Content-Sha256", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Date")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Date", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Credential")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Credential", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Security-Token")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Security-Token", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Algorithm")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Algorithm", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-SignedHeaders", valid_593391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593393: Call_ListAccountsForParent_593379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593393.validator(path, query, header, formData, body)
  let scheme = call_593393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593393.url(scheme.get, call_593393.host, call_593393.base,
                         call_593393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593393, url, valid)

proc call*(call_593394: Call_ListAccountsForParent_593379; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccountsForParent
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593395 = newJObject()
  var body_593396 = newJObject()
  add(query_593395, "MaxResults", newJString(MaxResults))
  add(query_593395, "NextToken", newJString(NextToken))
  if body != nil:
    body_593396 = body
  result = call_593394.call(nil, query_593395, nil, nil, body_593396)

var listAccountsForParent* = Call_ListAccountsForParent_593379(
    name: "listAccountsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccountsForParent",
    validator: validate_ListAccountsForParent_593380, base: "/",
    url: url_ListAccountsForParent_593381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChildren_593397 = ref object of OpenApiRestCall_592365
proc url_ListChildren_593399(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChildren_593398(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593400 = query.getOrDefault("MaxResults")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "MaxResults", valid_593400
  var valid_593401 = query.getOrDefault("NextToken")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "NextToken", valid_593401
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
  var valid_593402 = header.getOrDefault("X-Amz-Target")
  valid_593402 = validateParameter(valid_593402, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListChildren"))
  if valid_593402 != nil:
    section.add "X-Amz-Target", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Signature")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Signature", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Content-Sha256", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Date")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Date", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Credential")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Credential", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Security-Token")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Security-Token", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Algorithm")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Algorithm", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-SignedHeaders", valid_593409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593411: Call_ListChildren_593397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593411.validator(path, query, header, formData, body)
  let scheme = call_593411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593411.url(scheme.get, call_593411.host, call_593411.base,
                         call_593411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593411, url, valid)

proc call*(call_593412: Call_ListChildren_593397; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChildren
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593413 = newJObject()
  var body_593414 = newJObject()
  add(query_593413, "MaxResults", newJString(MaxResults))
  add(query_593413, "NextToken", newJString(NextToken))
  if body != nil:
    body_593414 = body
  result = call_593412.call(nil, query_593413, nil, nil, body_593414)

var listChildren* = Call_ListChildren_593397(name: "listChildren",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListChildren",
    validator: validate_ListChildren_593398, base: "/", url: url_ListChildren_593399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreateAccountStatus_593415 = ref object of OpenApiRestCall_592365
proc url_ListCreateAccountStatus_593417(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCreateAccountStatus_593416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593418 = query.getOrDefault("MaxResults")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "MaxResults", valid_593418
  var valid_593419 = query.getOrDefault("NextToken")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "NextToken", valid_593419
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
      "AWSOrganizationsV20161128.ListCreateAccountStatus"))
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

proc call*(call_593429: Call_ListCreateAccountStatus_593415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593429.validator(path, query, header, formData, body)
  let scheme = call_593429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593429.url(scheme.get, call_593429.host, call_593429.base,
                         call_593429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593429, url, valid)

proc call*(call_593430: Call_ListCreateAccountStatus_593415; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCreateAccountStatus
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593431 = newJObject()
  var body_593432 = newJObject()
  add(query_593431, "MaxResults", newJString(MaxResults))
  add(query_593431, "NextToken", newJString(NextToken))
  if body != nil:
    body_593432 = body
  result = call_593430.call(nil, query_593431, nil, nil, body_593432)

var listCreateAccountStatus* = Call_ListCreateAccountStatus_593415(
    name: "listCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListCreateAccountStatus",
    validator: validate_ListCreateAccountStatus_593416, base: "/",
    url: url_ListCreateAccountStatus_593417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForAccount_593433 = ref object of OpenApiRestCall_592365
proc url_ListHandshakesForAccount_593435(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHandshakesForAccount_593434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593436 = query.getOrDefault("MaxResults")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "MaxResults", valid_593436
  var valid_593437 = query.getOrDefault("NextToken")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "NextToken", valid_593437
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
  var valid_593438 = header.getOrDefault("X-Amz-Target")
  valid_593438 = validateParameter(valid_593438, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForAccount"))
  if valid_593438 != nil:
    section.add "X-Amz-Target", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Signature")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Signature", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Content-Sha256", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Date")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Date", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Credential")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Credential", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Security-Token")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Security-Token", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Algorithm")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Algorithm", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-SignedHeaders", valid_593445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593447: Call_ListHandshakesForAccount_593433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_593447.validator(path, query, header, formData, body)
  let scheme = call_593447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593447.url(scheme.get, call_593447.host, call_593447.base,
                         call_593447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593447, url, valid)

proc call*(call_593448: Call_ListHandshakesForAccount_593433; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForAccount
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593449 = newJObject()
  var body_593450 = newJObject()
  add(query_593449, "MaxResults", newJString(MaxResults))
  add(query_593449, "NextToken", newJString(NextToken))
  if body != nil:
    body_593450 = body
  result = call_593448.call(nil, query_593449, nil, nil, body_593450)

var listHandshakesForAccount* = Call_ListHandshakesForAccount_593433(
    name: "listHandshakesForAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForAccount",
    validator: validate_ListHandshakesForAccount_593434, base: "/",
    url: url_ListHandshakesForAccount_593435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForOrganization_593451 = ref object of OpenApiRestCall_592365
proc url_ListHandshakesForOrganization_593453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHandshakesForOrganization_593452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593454 = query.getOrDefault("MaxResults")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "MaxResults", valid_593454
  var valid_593455 = query.getOrDefault("NextToken")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "NextToken", valid_593455
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
  var valid_593456 = header.getOrDefault("X-Amz-Target")
  valid_593456 = validateParameter(valid_593456, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForOrganization"))
  if valid_593456 != nil:
    section.add "X-Amz-Target", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Signature")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Signature", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Content-Sha256", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Date")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Date", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Credential")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Credential", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Security-Token")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Security-Token", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Algorithm")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Algorithm", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-SignedHeaders", valid_593463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593465: Call_ListHandshakesForOrganization_593451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593465.validator(path, query, header, formData, body)
  let scheme = call_593465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593465.url(scheme.get, call_593465.host, call_593465.base,
                         call_593465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593465, url, valid)

proc call*(call_593466: Call_ListHandshakesForOrganization_593451; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForOrganization
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593467 = newJObject()
  var body_593468 = newJObject()
  add(query_593467, "MaxResults", newJString(MaxResults))
  add(query_593467, "NextToken", newJString(NextToken))
  if body != nil:
    body_593468 = body
  result = call_593466.call(nil, query_593467, nil, nil, body_593468)

var listHandshakesForOrganization* = Call_ListHandshakesForOrganization_593451(
    name: "listHandshakesForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForOrganization",
    validator: validate_ListHandshakesForOrganization_593452, base: "/",
    url: url_ListHandshakesForOrganization_593453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationalUnitsForParent_593469 = ref object of OpenApiRestCall_592365
proc url_ListOrganizationalUnitsForParent_593471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOrganizationalUnitsForParent_593470(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593472 = query.getOrDefault("MaxResults")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "MaxResults", valid_593472
  var valid_593473 = query.getOrDefault("NextToken")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "NextToken", valid_593473
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
  var valid_593474 = header.getOrDefault("X-Amz-Target")
  valid_593474 = validateParameter(valid_593474, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"))
  if valid_593474 != nil:
    section.add "X-Amz-Target", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Signature")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Signature", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Content-Sha256", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Date")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Date", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Credential")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Credential", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Security-Token")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Security-Token", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Algorithm")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Algorithm", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-SignedHeaders", valid_593481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593483: Call_ListOrganizationalUnitsForParent_593469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593483.validator(path, query, header, formData, body)
  let scheme = call_593483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593483.url(scheme.get, call_593483.host, call_593483.base,
                         call_593483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593483, url, valid)

proc call*(call_593484: Call_ListOrganizationalUnitsForParent_593469;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listOrganizationalUnitsForParent
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593485 = newJObject()
  var body_593486 = newJObject()
  add(query_593485, "MaxResults", newJString(MaxResults))
  add(query_593485, "NextToken", newJString(NextToken))
  if body != nil:
    body_593486 = body
  result = call_593484.call(nil, query_593485, nil, nil, body_593486)

var listOrganizationalUnitsForParent* = Call_ListOrganizationalUnitsForParent_593469(
    name: "listOrganizationalUnitsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListOrganizationalUnitsForParent",
    validator: validate_ListOrganizationalUnitsForParent_593470, base: "/",
    url: url_ListOrganizationalUnitsForParent_593471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParents_593487 = ref object of OpenApiRestCall_592365
proc url_ListParents_593489(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListParents_593488(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593490 = query.getOrDefault("MaxResults")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "MaxResults", valid_593490
  var valid_593491 = query.getOrDefault("NextToken")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "NextToken", valid_593491
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
  var valid_593492 = header.getOrDefault("X-Amz-Target")
  valid_593492 = validateParameter(valid_593492, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListParents"))
  if valid_593492 != nil:
    section.add "X-Amz-Target", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-Signature")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Signature", valid_593493
  var valid_593494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Content-Sha256", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Date")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Date", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Credential")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Credential", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Security-Token")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Security-Token", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Algorithm")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Algorithm", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-SignedHeaders", valid_593499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593501: Call_ListParents_593487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  let valid = call_593501.validator(path, query, header, formData, body)
  let scheme = call_593501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593501.url(scheme.get, call_593501.host, call_593501.base,
                         call_593501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593501, url, valid)

proc call*(call_593502: Call_ListParents_593487; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listParents
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593503 = newJObject()
  var body_593504 = newJObject()
  add(query_593503, "MaxResults", newJString(MaxResults))
  add(query_593503, "NextToken", newJString(NextToken))
  if body != nil:
    body_593504 = body
  result = call_593502.call(nil, query_593503, nil, nil, body_593504)

var listParents* = Call_ListParents_593487(name: "listParents",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListParents",
                                        validator: validate_ListParents_593488,
                                        base: "/", url: url_ListParents_593489,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_593505 = ref object of OpenApiRestCall_592365
proc url_ListPolicies_593507(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPolicies_593506(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593508 = query.getOrDefault("MaxResults")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "MaxResults", valid_593508
  var valid_593509 = query.getOrDefault("NextToken")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "NextToken", valid_593509
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
  var valid_593510 = header.getOrDefault("X-Amz-Target")
  valid_593510 = validateParameter(valid_593510, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPolicies"))
  if valid_593510 != nil:
    section.add "X-Amz-Target", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Signature")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Signature", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-Content-Sha256", valid_593512
  var valid_593513 = header.getOrDefault("X-Amz-Date")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Date", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Credential")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Credential", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Security-Token")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Security-Token", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Algorithm")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Algorithm", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-SignedHeaders", valid_593517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593519: Call_ListPolicies_593505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593519.validator(path, query, header, formData, body)
  let scheme = call_593519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593519.url(scheme.get, call_593519.host, call_593519.base,
                         call_593519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593519, url, valid)

proc call*(call_593520: Call_ListPolicies_593505; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicies
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593521 = newJObject()
  var body_593522 = newJObject()
  add(query_593521, "MaxResults", newJString(MaxResults))
  add(query_593521, "NextToken", newJString(NextToken))
  if body != nil:
    body_593522 = body
  result = call_593520.call(nil, query_593521, nil, nil, body_593522)

var listPolicies* = Call_ListPolicies_593505(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPolicies",
    validator: validate_ListPolicies_593506, base: "/", url: url_ListPolicies_593507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPoliciesForTarget_593523 = ref object of OpenApiRestCall_592365
proc url_ListPoliciesForTarget_593525(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPoliciesForTarget_593524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593526 = query.getOrDefault("MaxResults")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "MaxResults", valid_593526
  var valid_593527 = query.getOrDefault("NextToken")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "NextToken", valid_593527
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
      "AWSOrganizationsV20161128.ListPoliciesForTarget"))
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

proc call*(call_593537: Call_ListPoliciesForTarget_593523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593537.validator(path, query, header, formData, body)
  let scheme = call_593537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593537.url(scheme.get, call_593537.host, call_593537.base,
                         call_593537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593537, url, valid)

proc call*(call_593538: Call_ListPoliciesForTarget_593523; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPoliciesForTarget
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593539 = newJObject()
  var body_593540 = newJObject()
  add(query_593539, "MaxResults", newJString(MaxResults))
  add(query_593539, "NextToken", newJString(NextToken))
  if body != nil:
    body_593540 = body
  result = call_593538.call(nil, query_593539, nil, nil, body_593540)

var listPoliciesForTarget* = Call_ListPoliciesForTarget_593523(
    name: "listPoliciesForTarget", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPoliciesForTarget",
    validator: validate_ListPoliciesForTarget_593524, base: "/",
    url: url_ListPoliciesForTarget_593525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoots_593541 = ref object of OpenApiRestCall_592365
proc url_ListRoots_593543(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRoots_593542(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593544 = query.getOrDefault("MaxResults")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "MaxResults", valid_593544
  var valid_593545 = query.getOrDefault("NextToken")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "NextToken", valid_593545
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
  var valid_593546 = header.getOrDefault("X-Amz-Target")
  valid_593546 = validateParameter(valid_593546, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListRoots"))
  if valid_593546 != nil:
    section.add "X-Amz-Target", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Signature")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Signature", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Content-Sha256", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Date")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Date", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Credential")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Credential", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Security-Token")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Security-Token", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Algorithm")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Algorithm", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-SignedHeaders", valid_593553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593555: Call_ListRoots_593541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  let valid = call_593555.validator(path, query, header, formData, body)
  let scheme = call_593555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593555.url(scheme.get, call_593555.host, call_593555.base,
                         call_593555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593555, url, valid)

proc call*(call_593556: Call_ListRoots_593541; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRoots
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593557 = newJObject()
  var body_593558 = newJObject()
  add(query_593557, "MaxResults", newJString(MaxResults))
  add(query_593557, "NextToken", newJString(NextToken))
  if body != nil:
    body_593558 = body
  result = call_593556.call(nil, query_593557, nil, nil, body_593558)

var listRoots* = Call_ListRoots_593541(name: "listRoots", meth: HttpMethod.HttpPost,
                                    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListRoots",
                                    validator: validate_ListRoots_593542,
                                    base: "/", url: url_ListRoots_593543,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593559 = ref object of OpenApiRestCall_592365
proc url_ListTagsForResource_593561(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593560(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593562 = query.getOrDefault("NextToken")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "NextToken", valid_593562
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
  var valid_593563 = header.getOrDefault("X-Amz-Target")
  valid_593563 = validateParameter(valid_593563, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTagsForResource"))
  if valid_593563 != nil:
    section.add "X-Amz-Target", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Signature")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Signature", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Content-Sha256", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Date")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Date", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Credential")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Credential", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Security-Token")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Security-Token", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Algorithm")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Algorithm", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-SignedHeaders", valid_593570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593572: Call_ListTagsForResource_593559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p>
  ## 
  let valid = call_593572.validator(path, query, header, formData, body)
  let scheme = call_593572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593572.url(scheme.get, call_593572.host, call_593572.base,
                         call_593572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593572, url, valid)

proc call*(call_593573: Call_ListTagsForResource_593559; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593574 = newJObject()
  var body_593575 = newJObject()
  add(query_593574, "NextToken", newJString(NextToken))
  if body != nil:
    body_593575 = body
  result = call_593573.call(nil, query_593574, nil, nil, body_593575)

var listTagsForResource* = Call_ListTagsForResource_593559(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_593560, base: "/",
    url: url_ListTagsForResource_593561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsForPolicy_593576 = ref object of OpenApiRestCall_592365
proc url_ListTargetsForPolicy_593578(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTargetsForPolicy_593577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593579 = query.getOrDefault("MaxResults")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "MaxResults", valid_593579
  var valid_593580 = query.getOrDefault("NextToken")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "NextToken", valid_593580
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
  var valid_593581 = header.getOrDefault("X-Amz-Target")
  valid_593581 = validateParameter(valid_593581, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTargetsForPolicy"))
  if valid_593581 != nil:
    section.add "X-Amz-Target", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Signature")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Signature", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Content-Sha256", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Date")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Date", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Credential")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Credential", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Security-Token")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Security-Token", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Algorithm")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Algorithm", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-SignedHeaders", valid_593588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593590: Call_ListTargetsForPolicy_593576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593590.validator(path, query, header, formData, body)
  let scheme = call_593590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593590.url(scheme.get, call_593590.host, call_593590.base,
                         call_593590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593590, url, valid)

proc call*(call_593591: Call_ListTargetsForPolicy_593576; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargetsForPolicy
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593592 = newJObject()
  var body_593593 = newJObject()
  add(query_593592, "MaxResults", newJString(MaxResults))
  add(query_593592, "NextToken", newJString(NextToken))
  if body != nil:
    body_593593 = body
  result = call_593591.call(nil, query_593592, nil, nil, body_593593)

var listTargetsForPolicy* = Call_ListTargetsForPolicy_593576(
    name: "listTargetsForPolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTargetsForPolicy",
    validator: validate_ListTargetsForPolicy_593577, base: "/",
    url: url_ListTargetsForPolicy_593578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MoveAccount_593594 = ref object of OpenApiRestCall_592365
proc url_MoveAccount_593596(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MoveAccount_593595(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593597 = header.getOrDefault("X-Amz-Target")
  valid_593597 = validateParameter(valid_593597, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.MoveAccount"))
  if valid_593597 != nil:
    section.add "X-Amz-Target", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Signature")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Signature", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Content-Sha256", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Date")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Date", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Credential")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Credential", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Security-Token")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Security-Token", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Algorithm")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Algorithm", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-SignedHeaders", valid_593604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593606: Call_MoveAccount_593594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593606.validator(path, query, header, formData, body)
  let scheme = call_593606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593606.url(scheme.get, call_593606.host, call_593606.base,
                         call_593606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593606, url, valid)

proc call*(call_593607: Call_MoveAccount_593594; body: JsonNode): Recallable =
  ## moveAccount
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593608 = newJObject()
  if body != nil:
    body_593608 = body
  result = call_593607.call(nil, nil, nil, nil, body_593608)

var moveAccount* = Call_MoveAccount_593594(name: "moveAccount",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.MoveAccount",
                                        validator: validate_MoveAccount_593595,
                                        base: "/", url: url_MoveAccount_593596,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAccountFromOrganization_593609 = ref object of OpenApiRestCall_592365
proc url_RemoveAccountFromOrganization_593611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveAccountFromOrganization_593610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
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
  var valid_593612 = header.getOrDefault("X-Amz-Target")
  valid_593612 = validateParameter(valid_593612, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.RemoveAccountFromOrganization"))
  if valid_593612 != nil:
    section.add "X-Amz-Target", valid_593612
  var valid_593613 = header.getOrDefault("X-Amz-Signature")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "X-Amz-Signature", valid_593613
  var valid_593614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "X-Amz-Content-Sha256", valid_593614
  var valid_593615 = header.getOrDefault("X-Amz-Date")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "X-Amz-Date", valid_593615
  var valid_593616 = header.getOrDefault("X-Amz-Credential")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Credential", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-Security-Token")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Security-Token", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Algorithm")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Algorithm", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-SignedHeaders", valid_593619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593621: Call_RemoveAccountFromOrganization_593609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ## 
  let valid = call_593621.validator(path, query, header, formData, body)
  let scheme = call_593621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593621.url(scheme.get, call_593621.host, call_593621.base,
                         call_593621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593621, url, valid)

proc call*(call_593622: Call_RemoveAccountFromOrganization_593609; body: JsonNode): Recallable =
  ## removeAccountFromOrganization
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ##   body: JObject (required)
  var body_593623 = newJObject()
  if body != nil:
    body_593623 = body
  result = call_593622.call(nil, nil, nil, nil, body_593623)

var removeAccountFromOrganization* = Call_RemoveAccountFromOrganization_593609(
    name: "removeAccountFromOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.RemoveAccountFromOrganization",
    validator: validate_RemoveAccountFromOrganization_593610, base: "/",
    url: url_RemoveAccountFromOrganization_593611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593624 = ref object of OpenApiRestCall_592365
proc url_TagResource_593626(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593625(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
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
  var valid_593627 = header.getOrDefault("X-Amz-Target")
  valid_593627 = validateParameter(valid_593627, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.TagResource"))
  if valid_593627 != nil:
    section.add "X-Amz-Target", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Signature")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Signature", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Content-Sha256", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-Date")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-Date", valid_593630
  var valid_593631 = header.getOrDefault("X-Amz-Credential")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Credential", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Security-Token")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Security-Token", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Algorithm")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Algorithm", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-SignedHeaders", valid_593634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593636: Call_TagResource_593624; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ## 
  let valid = call_593636.validator(path, query, header, formData, body)
  let scheme = call_593636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593636.url(scheme.get, call_593636.host, call_593636.base,
                         call_593636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593636, url, valid)

proc call*(call_593637: Call_TagResource_593624; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ##   body: JObject (required)
  var body_593638 = newJObject()
  if body != nil:
    body_593638 = body
  result = call_593637.call(nil, nil, nil, nil, body_593638)

var tagResource* = Call_TagResource_593624(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.TagResource",
                                        validator: validate_TagResource_593625,
                                        base: "/", url: url_TagResource_593626,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593639 = ref object of OpenApiRestCall_592365
proc url_UntagResource_593641(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593640(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
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
  var valid_593642 = header.getOrDefault("X-Amz-Target")
  valid_593642 = validateParameter(valid_593642, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UntagResource"))
  if valid_593642 != nil:
    section.add "X-Amz-Target", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Signature")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Signature", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Content-Sha256", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-Date")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-Date", valid_593645
  var valid_593646 = header.getOrDefault("X-Amz-Credential")
  valid_593646 = validateParameter(valid_593646, JString, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "X-Amz-Credential", valid_593646
  var valid_593647 = header.getOrDefault("X-Amz-Security-Token")
  valid_593647 = validateParameter(valid_593647, JString, required = false,
                                 default = nil)
  if valid_593647 != nil:
    section.add "X-Amz-Security-Token", valid_593647
  var valid_593648 = header.getOrDefault("X-Amz-Algorithm")
  valid_593648 = validateParameter(valid_593648, JString, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "X-Amz-Algorithm", valid_593648
  var valid_593649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-SignedHeaders", valid_593649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593651: Call_UntagResource_593639; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ## 
  let valid = call_593651.validator(path, query, header, formData, body)
  let scheme = call_593651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593651.url(scheme.get, call_593651.host, call_593651.base,
                         call_593651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593651, url, valid)

proc call*(call_593652: Call_UntagResource_593639; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ##   body: JObject (required)
  var body_593653 = newJObject()
  if body != nil:
    body_593653 = body
  result = call_593652.call(nil, nil, nil, nil, body_593653)

var untagResource* = Call_UntagResource_593639(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UntagResource",
    validator: validate_UntagResource_593640, base: "/", url: url_UntagResource_593641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOrganizationalUnit_593654 = ref object of OpenApiRestCall_592365
proc url_UpdateOrganizationalUnit_593656(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateOrganizationalUnit_593655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593657 = header.getOrDefault("X-Amz-Target")
  valid_593657 = validateParameter(valid_593657, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdateOrganizationalUnit"))
  if valid_593657 != nil:
    section.add "X-Amz-Target", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Signature")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Signature", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Content-Sha256", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Date")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Date", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Credential")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Credential", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Security-Token")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Security-Token", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-Algorithm")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-Algorithm", valid_593663
  var valid_593664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-SignedHeaders", valid_593664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593666: Call_UpdateOrganizationalUnit_593654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593666.validator(path, query, header, formData, body)
  let scheme = call_593666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593666.url(scheme.get, call_593666.host, call_593666.base,
                         call_593666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593666, url, valid)

proc call*(call_593667: Call_UpdateOrganizationalUnit_593654; body: JsonNode): Recallable =
  ## updateOrganizationalUnit
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593668 = newJObject()
  if body != nil:
    body_593668 = body
  result = call_593667.call(nil, nil, nil, nil, body_593668)

var updateOrganizationalUnit* = Call_UpdateOrganizationalUnit_593654(
    name: "updateOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdateOrganizationalUnit",
    validator: validate_UpdateOrganizationalUnit_593655, base: "/",
    url: url_UpdateOrganizationalUnit_593656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePolicy_593669 = ref object of OpenApiRestCall_592365
proc url_UpdatePolicy_593671(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePolicy_593670(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_593672 = header.getOrDefault("X-Amz-Target")
  valid_593672 = validateParameter(valid_593672, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdatePolicy"))
  if valid_593672 != nil:
    section.add "X-Amz-Target", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Signature")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Signature", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Content-Sha256", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Date")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Date", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Credential")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Credential", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Security-Token")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Security-Token", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Algorithm")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Algorithm", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-SignedHeaders", valid_593679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593681: Call_UpdatePolicy_593669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_593681.validator(path, query, header, formData, body)
  let scheme = call_593681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593681.url(scheme.get, call_593681.host, call_593681.base,
                         call_593681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593681, url, valid)

proc call*(call_593682: Call_UpdatePolicy_593669; body: JsonNode): Recallable =
  ## updatePolicy
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_593683 = newJObject()
  if body != nil:
    body_593683 = body
  result = call_593682.call(nil, nil, nil, nil, body_593683)

var updatePolicy* = Call_UpdatePolicy_593669(name: "updatePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdatePolicy",
    validator: validate_UpdatePolicy_593670, base: "/", url: url_UpdatePolicy_593671,
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
